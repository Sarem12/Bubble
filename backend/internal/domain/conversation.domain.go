package domain

import (
	"context"
	"time"
)

type Conversation struct {
	ID        string    `json:"id"`
	User1ID   string    `json:"user1_id"`
	User2ID   string    `json:"user2_id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type EnrichedConversation struct {
	ID          string    `json:"id"`
	FriendID    string    `json:"friend_id"`
	Username    string    `json:"username"`
	Avatar      string    `json:"avatar"`
	LastMessage string    `json:"last_message"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type ConversationRepository interface {
	CreateOrGet(ctx context.Context, u1, u2 string) (*Conversation, error)
	GetConversationsForUser(ctx context.Context, userID string) ([]*Conversation, error)
}

type ConversationService interface {
	CreateOrGetConversation(ctx context.Context, currentUserID, targetUserID string) (*Conversation, error)
	GetConversations(ctx context.Context, userID string) ([]*EnrichedConversation, error)
}
