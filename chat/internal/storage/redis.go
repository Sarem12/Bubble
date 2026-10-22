package storage

import (
	"context"
	"encoding/json"
	"fmt"
	"time"
	"chat/internal/config"
)

type OfflineEvent struct {
	SenderID       string `json:"sender_id"`
	RecipientID    string `json:"recipient_id"`
	ConversationID string `json:"conversation_id"`
	Content        string `json:"content"`
	Timestamp      int64  `json:"timestamp"`
}

func PushOfflineEvent(ctx context.Context, event OfflineEvent) error {
	data, err := json.Marshal(event)
	if err != nil {
		return err
	}
	return config.RedisClient.LPush(ctx, "chat_notifications", data).Err()
}

func SetUserPresence(ctx context.Context, userID string, isOnline bool) error {
	key := fmt.Sprintf("presence:%s", userID)
	if isOnline {
		return config.RedisClient.Set(ctx, key, "online", 2*time.Hour).Err()
	}
	return config.RedisClient.Del(ctx, key).Err()
}

func GetUserPresence(ctx context.Context, userID string) (bool, error) {
	key := fmt.Sprintf("presence:%s", userID)
	val, err := config.RedisClient.Get(ctx, key).Result()
	if err != nil {
		return false, nil
	}
	return val == "online", nil
}
