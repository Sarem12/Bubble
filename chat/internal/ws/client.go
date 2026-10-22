package ws

import (
	"log"
	"time"
	"encoding/json"

	"github.com/gofiber/contrib/websocket"
)

const (
	writeWait      = 5 * time.Second
	pongWait       = 15 * time.Second
	pingPeriod     = 7 * time.Second
	maxMessageSize = 5120
)

type Client struct {
	Hub      *Hub
	Conn     *websocket.Conn
	UserID   string
	DeviceID string
	Send     chan []byte
}

func (c *Client) ReadPump() {
	defer func() {
		c.Hub.Unregister <- c
		c.Conn.Close()
	}()
	c.Conn.SetReadLimit(maxMessageSize)
	c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	c.Conn.SetPongHandler(func(string) error { c.Conn.SetReadDeadline(time.Now().Add(pongWait)); return nil })

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}
		
		var payload ChatPayload
		if err := json.Unmarshal(message, &payload); err == nil {
			c.Hub.Inbound <- &MessageEvent{
				Client:  c,
				Payload: payload,
			}
		} else {
			log.Printf("Invalid message payload: %v", err)
		}
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()
	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// The hub closed the channel.
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			if err := c.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}
		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
