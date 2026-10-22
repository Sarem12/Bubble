package ws

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"chat/internal/storage"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Hub struct {
	Clients    map[string][]*Client
	Inbound    chan *MessageEvent
	Register   chan *Client
	Unregister chan *Client
	mu         sync.RWMutex
}

type MessageEvent struct {
	Client  *Client
	Payload ChatPayload
}

func NewHub() *Hub {
	return &Hub{
		Inbound:    make(chan *MessageEvent),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
		Clients:    make(map[string][]*Client),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			wasOnline := len(h.Clients[client.UserID]) > 0
			h.Clients[client.UserID] = append(h.Clients[client.UserID], client)
			h.mu.Unlock()

			// Update Presence in Redis
			go storage.SetUserPresence(context.Background(), client.UserID, true)

			log.Printf("Client registered: %s (Device: %s)", client.UserID, client.DeviceID)

			if !wasOnline {
				go h.broadcastPresence(client.UserID, "online")
			}

		case client := <-h.Unregister:
			h.mu.Lock()
			becameOffline := false
			if devices, ok := h.Clients[client.UserID]; ok {
				for i, c := range devices {
					if c == client {
						h.Clients[client.UserID] = append(devices[:i], devices[i+1:]...)
						close(client.Send)
						break
					}
				}
				if len(h.Clients[client.UserID]) == 0 {
					delete(h.Clients, client.UserID)
					becameOffline = true
				}
			}
			h.mu.Unlock()
			log.Printf("Client unregistered: %s (Device: %s)", client.UserID, client.DeviceID)

			if becameOffline {
				uid := client.UserID
				go func(userID string) {
					storage.SetUserPresence(context.Background(), userID, false)

					req, err := http.NewRequest(http.MethodPut, "http://127.0.0.1:3000/api/users/"+userID+"/last-active", nil)
					if err == nil {
						http.DefaultClient.Do(req)
					}
				}(uid)

				go h.broadcastPresence(uid, "offline")
			}

		case event := <-h.Inbound:
			h.handleInboundMessage(event)
		}
	}
}

func (h *Hub) broadcastPresence(userID string, status string) {
	payload, err := json.Marshal(map[string]interface{}{
		"type":    "presence_update",
		"user_id": userID,
		"status":  status,
	})
	if err != nil {
		return
	}

	h.mu.RLock()
	defer h.mu.RUnlock()
	for uid, devices := range h.Clients {
		if uid == userID {
			continue
		}
		for _, c := range devices {
			select {
			case c.Send <- payload:
			default:
			}
		}
	}
}

func (h *Hub) handleInboundMessage(event *MessageEvent) {
	if event.Payload.Action == "typing" {
		h.mu.RLock()
		targetDevices, isOnline := h.Clients[event.Payload.RecipientID]
		h.mu.RUnlock()
		if isOnline && len(targetDevices) > 0 {
			typingPayload := map[string]interface{}{
				"type":            "typing",
				"conversation_id": event.Payload.ConversationID,
				"sender_id":       event.Client.UserID,
			}
			typingBytes, _ := json.Marshal(typingPayload)
			for _, targetClient := range targetDevices {
				select {
				case targetClient.Send <- typingBytes:
				default:
				}
			}
		}
		return
	}

	if event.Payload.Action == "mark_read" {
		now, _ := storage.MarkMessagesAsRead(context.Background(), event.Payload.ConversationID, event.Client.UserID)

		recipientID := event.Payload.RecipientID
		if recipientID == "" {
			conv, err := storage.GetConversationByID(context.Background(), event.Payload.ConversationID)
			if err == nil && conv != nil {
				for _, p := range conv.Participants {
					if p != event.Client.UserID {
						recipientID = p
						break
					}
				}
			}
		}

		h.mu.RLock()
		targetDevices, isOnline := h.Clients[recipientID]
		h.mu.RUnlock()
		if isOnline && len(targetDevices) > 0 {
			readPayload := map[string]interface{}{
				"type":            "read_receipt",
				"conversation_id": event.Payload.ConversationID,
				"reader_id":       event.Client.UserID,
				"read_at":         now.Format(time.RFC3339Nano),
			}
			readBytes, _ := json.Marshal(readPayload)
			for _, targetClient := range targetDevices {
				select {
				case targetClient.Send <- readBytes:
				default:
				}
			}
		}
		return
	}

	if event.Payload.Action == "delete_message" {
		go storage.DeleteMessage(context.Background(), event.Payload.MessageID, event.Payload.ConversationID)

		delPayload := map[string]interface{}{
			"type":            "delete_message",
			"conversation_id": event.Payload.ConversationID,
			"message_id":      event.Payload.MessageID,
		}
		delBytes, _ := json.Marshal(delPayload)

		h.mu.RLock()
		recipients := []string{event.Client.UserID, event.Payload.RecipientID}
		for _, uid := range recipients {
			if uid == "" {
				continue
			}
			for _, client := range h.Clients[uid] {
				select {
				case client.Send <- delBytes:
				default:
				}
			}
		}
		h.mu.RUnlock()
		return
	}

	if event.Payload.Action == "react_message" {
		go func() {
			reactions, err := storage.ToggleReaction(context.Background(), event.Payload.MessageID, event.Client.UserID, event.Payload.Emoji)
			if err != nil {
				return
			}

			reactPayload := map[string]interface{}{
				"type":            "reaction_update",
				"conversation_id": event.Payload.ConversationID,
				"message_id":      event.Payload.MessageID,
				"reactions":       reactions,
			}
			reactBytes, _ := json.Marshal(reactPayload)

			h.mu.RLock()
			recipients := []string{event.Client.UserID, event.Payload.RecipientID}
			for _, uid := range recipients {
				if uid == "" {
					continue
				}
				for _, client := range h.Clients[uid] {
					select {
					case client.Send <- reactBytes:
					default:
					}
				}
			}
			h.mu.RUnlock()
		}()
		return
	}

	if event.Payload.Action == "delete_conversation" {
		go storage.DeleteConversation(context.Background(), event.Payload.ConversationID)

		convDelPayload := map[string]interface{}{
			"type":            "conversation_deleted",
			"conversation_id": event.Payload.ConversationID,
		}
		convDelBytes, _ := json.Marshal(convDelPayload)

		h.mu.RLock()
		recipients := []string{event.Client.UserID, event.Payload.RecipientID}
		for _, uid := range recipients {
			if uid == "" {
				continue
			}
			for _, client := range h.Clients[uid] {
				select {
				case client.Send <- convDelBytes:
				default:
				}
			}
		}
		h.mu.RUnlock()
		return
	}

	if event.Payload.Action != "send_message" {
		return
	}

	topic := event.Payload.Topic
	if topic == "" {
		topic = "main"
	}

	recipientID := event.Payload.RecipientID
	if recipientID == "" {
		conv, err := storage.GetConversationByID(context.Background(), event.Payload.ConversationID)
		if err == nil && conv != nil {
			for _, p := range conv.Participants {
				if p != event.Client.UserID {
					recipientID = p
					break
				}
			}
		}
	}

	msg := storage.Message{
		ID:             primitive.NewObjectID(),
		ConversationID: event.Payload.ConversationID,
		Topic:          topic,
		SenderID:       event.Client.UserID,
		RecipientID:    recipientID,
		Content:        event.Payload.Content,
		CreatedAt:      time.Now(),
	}

	// 1. Immediate Persistence to MongoDB
	ctx := context.Background()
	if err := storage.SaveMessage(ctx, &msg); err != nil {
		log.Printf("Failed to save message to Mongo: %v", err)
		return
	}

	// 2. Online Routing Check
	h.mu.RLock()
	targetDevices, isOnline := h.Clients[msg.RecipientID]
	senderDevices := h.Clients[msg.SenderID]
	h.mu.RUnlock()

	msgBytes, _ := json.Marshal(map[string]interface{}{
		"type":            "new_message",
		"conversation_id": msg.ConversationID,
		"client_id":       event.Payload.ClientID,
		"message":         msg,
	})

	// Echo to sender devices
	for _, sClient := range senderDevices {
		select {
		case sClient.Send <- msgBytes:
		default:
		}
	}

	if isOnline && len(targetDevices) > 0 {
		// Scenario A: Recipient is Online
		for _, targetClient := range targetDevices {
			select {
			case targetClient.Send <- msgBytes:
			default:
			}
		}
	} else {
		// Scenario B: Recipient is Offline -> Push to Redis
		offlineEvent := storage.OfflineEvent{
			SenderID:       msg.SenderID,
			RecipientID:    msg.RecipientID,
			ConversationID: msg.ConversationID,
			Content:        msg.Content,
			Timestamp:      msg.CreatedAt.Unix(),
		}
		if err := storage.PushOfflineEvent(ctx, offlineEvent); err != nil {
			log.Printf("Failed to push offline event to Redis: %v", err)
		}
	}
}
