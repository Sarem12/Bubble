package main

import (
	"log"
	"os"

	"chat/internal/config"
	"chat/internal/ws"
	"chat/internal/auth"
	"chat/internal/api"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/contrib/websocket"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, relying on environment variables")
	}

	config.InitMongo()
	config.InitRedis()

	app := fiber.New()
	app.Use(logger.New())

	apiGroup := app.Group("/api", api.AuthMiddleware)
	apiGroup.Get("/conversations", api.GetConversations)
	apiGroup.Get("/conversations/last-messages", api.GetLastMessages)
	apiGroup.Get("/conversations/:id/messages", api.GetMessages)
	apiGroup.Delete("/conversations/:id", api.DeleteConversation)
	apiGroup.Delete("/messages/:id", api.DeleteMessage)
	apiGroup.Post("/messages/:id/reactions", api.ToggleReaction)
	apiGroup.Get("/presence/:id", api.GetPresence)

	// Allow presence to be queried without auth requirement
	app.Get("/api/presence/:id", api.GetPresence)


	hub := ws.NewHub()
	go hub.Run()

	app.Use("/ws", func(c *fiber.Ctx) error {
		if websocket.IsWebSocketUpgrade(c) {
			c.Locals("allowed", true)
			return c.Next()
		}
		return fiber.ErrUpgradeRequired
	})

	app.Get("/ws", websocket.New(func(c *websocket.Conn) {
		token := c.Query("token")
		deviceID := c.Query("device_id")

		if token == "" || deviceID == "" {
			log.Println("Missing token or device_id")
			c.Close()
			return
		}

		userID, err := auth.ValidateToken(token)
		if err != nil {
			log.Println("Invalid token:", err)
			c.Close()
			return
		}

		client := &ws.Client{
			Hub:      hub,
			Conn:     c,
			UserID:   userID,
			DeviceID: deviceID,
			Send:     make(chan []byte, 256),
		}

		client.Hub.Register <- client

		// Allow collection of memory referenced by the caller by doing all work in
		// new goroutines.
		go client.WritePump()
		client.ReadPump()
	}))

	port := os.Getenv("PORT")
	if port == "" {
		port = "4000"
	}

	log.Printf("Chat Gateway running on port %s", port)
	log.Fatal(app.Listen(":" + port))
}
