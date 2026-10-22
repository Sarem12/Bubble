package worker

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"time"
	"bubble-api/internal/config"
	"firebase.google.com/go/v4/messaging"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

type OfflineEvent struct {
	SenderID       string `json:"sender_id"`
	RecipientID    string `json:"recipient_id"`
	ConversationID string `json:"conversation_id"`
	Content        string `json:"content"`
	Timestamp      int64  `json:"timestamp"`
}

func StartPushWorker(db *pgxpool.Pool) {
	addr := os.Getenv("REDIS_ADDR")
	if addr == "" {
		addr = "localhost:6379"
	}
	password := os.Getenv("REDIS_PASSWORD")

	rdb := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
		DB:       0,
	})

	log.Println("Push Notification Worker started. Listening on chat_notifications...")

	for {
		// BRPOP blocks until an event is pushed, consuming 0 CPU
		result, err := rdb.BRPop(context.Background(), 0, "chat_notifications").Result()
		if err != nil {
			log.Printf("Redis BRPOP error: %v", err)
			time.Sleep(2 * time.Second)
			continue
		}

		if len(result) < 2 {
			continue
		}

		payload := result[1]
		var event OfflineEvent
		if err := json.Unmarshal([]byte(payload), &event); err != nil {
			log.Printf("Invalid offline event JSON: %v", err)
			continue
		}

		go processOfflineEvent(db, event)
	}
}

func processOfflineEvent(db *pgxpool.Pool, event OfflineEvent) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Query PostgreSQL for Bob's active fcm_tokens
	query := `
		SELECT fcm_token 
		FROM sessions 
		WHERE user_id = $1 
		  AND is_revoked = false 
		  AND fcm_token IS NOT NULL 
		  AND fcm_token != ''
	`
	
	rows, err := db.Query(ctx, query, event.RecipientID)
	if err != nil {
		log.Printf("Failed to fetch FCM tokens for user %s: %v", event.RecipientID, err)
		return
	}
	defer rows.Close()

	var tokens []string
	for rows.Next() {
		var token string
		if err := rows.Scan(&token); err == nil {
			tokens = append(tokens, token)
		}
	}

	if len(tokens) == 0 {
		return // No active push tokens
	}

	if config.FCMClient == nil {
		log.Printf("-> [FCM Dispatch Mock] Sending push to %d devices for user %s (Firebase not init)", len(tokens), event.RecipientID)
		return
	}

	// Send an actual push notification to every active device the user owns
	for _, token := range tokens {
		msg := &messaging.Message{
			Token: token,
			Notification: &messaging.Notification{
				Title: "New Message",
				Body:  event.Content,
			},
			Data: map[string]string{
				"conversation_id": event.ConversationID,
				"sender_id":       event.SenderID,
				"type":            "chat_message",
			},
		}

		response, fcmErr := config.FCMClient.Send(ctx, msg)
		if fcmErr != nil {
			log.Printf("Error sending FCM to user %s: %v", event.RecipientID, fcmErr)
		} else {
			log.Printf("Successfully sent FCM message: %s", response)
		}
	}
}
