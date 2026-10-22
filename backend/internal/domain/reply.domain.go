package domain

import (
	"context"
	"time"
)

type Reply struct {
	ID                string         `json:"id"`
	PostID            string         `json:"post_id"`
	UserID            string         `json:"user_id"`
	Username          string         `json:"username"`
	FirstName         string         `json:"first_name"`
	LastName          string         `json:"last_name"`
	ProfilePictureURL string         `json:"profile_picture_url"`
	Content           string         `json:"content"`
	ParentReplyID     *string        `json:"parent_reply_id"`
	ParentUsername    *string        `json:"parent_username,omitempty"`
	CreatedAt         time.Time      `json:"created_at"`
	LikesCount        int            `json:"likes_count"`
	ReactionCounts    map[string]int `json:"reaction_counts"`
	RepliesCount      int            `json:"replies_count"`
	UserEmoji         *string        `json:"user_emoji,omitempty"`
}

type ReplyInteraction struct {
	UserID    string    `json:"user_id"`
	ReplyID   string    `json:"reply_id"`
	EmojiType string    `json:"emoji_type"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type ReplyRepository interface {
	Create(ctx context.Context, reply *Reply) error
	GetByID(ctx context.Context, id string, requestingUserID string) (*Reply, error)
	GetByPostID(ctx context.Context, postID string, requestingUserID string) ([]*Reply, error)
	Update(ctx context.Context, reply *Reply) error
	Delete(ctx context.Context, id string) error
	ReactToReply(ctx context.Context, userID, replyID, emojiType string) error
	RemoveReaction(ctx context.Context, userID, replyID string) error
}

type ReplyService interface {
	CreateReply(ctx context.Context, userID, postID, content string, parentReplyID *string) (*Reply, error)
	GetReplyByID(ctx context.Context, id string, requestingUserID string) (*Reply, error)
	GetRepliesByPostID(ctx context.Context, postID string, requestingUserID string) ([]*Reply, error)
	UpdateReply(ctx context.Context, id, userID, content string) (*Reply, error)
	DeleteReply(ctx context.Context, id, userID string) error
	ReactToReply(ctx context.Context, userID, replyID, emojiType string) (*Reply, error)
	RemoveReaction(ctx context.Context, userID, replyID string) (*Reply, error)
}
