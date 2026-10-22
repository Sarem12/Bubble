package domain

import (
	"context"
	"time"
)

type PostInteraction struct {
	UserID		string		`json:"user_id"`
	PostID		string		`json:"post_id"`
	EmojiType	*string		`json:"emoji_type,omitempty"`
	LastViewedAt	*time.Time	`json:"last_viewed_at,omitempty"`
	IsSaved		bool		`json:"is_saved"`
	IsShared	bool		`json:"is_shared"`
	CreatedAt	time.Time	`json:"created_at"`
	UpdatedAt	time.Time	`json:"updated_at"`
}

type PostInteractionRepository interface {
	UpsertReaction(ctx context.Context, interaction *PostInteraction) (*PostInteraction, error)
	UpsertSave(ctx context.Context, interaction *PostInteraction) (*PostInteraction, error)
	UpsertShare(ctx context.Context, interaction *PostInteraction) (*PostInteraction, error)
	UpsertView(ctx context.Context, interaction *PostInteraction) (*PostInteraction, error)
	GetInteraction(ctx context.Context, userID, postID string) (*PostInteraction, error)
	GetInteractionsByPost(ctx context.Context, postID string) ([]*PostInteraction, error)
	RemoveReaction(ctx context.Context, userID, postID string) error
}

type PostInteractionService interface {
	ReactToPost(ctx context.Context, userID, postID, emojiType string) (*PostInteraction, error)
	RemoveReaction(ctx context.Context, userID, postID string) error
	SavePost(ctx context.Context, userID, postID string, isSaved bool) (*PostInteraction, error)
	SharePost(ctx context.Context, userID, postID string) (*PostInteraction, error)
	ViewPost(ctx context.Context, userID, postID string) (*PostInteraction, error)
	GetInteractionsByPost(ctx context.Context, postID string) ([]*PostInteraction, error)
}
