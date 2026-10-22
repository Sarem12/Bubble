package domain

import (
	"context"
	"errors"
	"time"
)

var (
	ErrBubbleNotFound          = errors.New("bubble not found")
	ErrPersonalBubbleNotFound  = errors.New("no personal bubble was found")
	ErrNotAuthorized           = errors.New("you do not have permission to view this post")
	ErrMustJoinAll             = errors.New("you must join all selected bubbles before posting")
	ErrCannotPostInOtherPerson = errors.New("you cannot post in someone else's personal bubble")
	ErrMissingContent          = errors.New("post must have content or media")
)

type Post struct {
	ID         string       `json:"id"`
	UserID     string       `json:"user_id"`
	BubbleID   string       `json:"bubble_id"`
	BubbleName string       `json:"bubble_name,omitempty"`
	BubbleIDs  []string     `json:"bubble_ids,omitempty"`
	Content    string       `json:"content"`
	CreatedAt  time.Time    `json:"created_at"`
	Media      []*PostMedia `json:"media,omitempty"`
}

type PostNotificationSettings struct {
	PostID    string `json:"post_id"`
	Content   string `json:"content"`
	Reactions string `json:"reactions_notification"`
	Comments  string `json:"comments_notification"`
	Replies   string `json:"replies_notification"`
}

type UpdatePostNotificationParams struct {
	Reactions *string
	Comments  *string
	Replies   *string
}

type PostRepository interface {
	Create(ctx context.Context, post *Post) error
	GetByID(ctx context.Context, id string) (*Post, error)
	GetByBubbleID(ctx context.Context, bubbleID string) ([]*Post, error)
	Update(ctx context.Context, post *Post) error
	Delete(ctx context.Context, id string) error
	GetUserNotificationSettings(ctx context.Context, userID string) ([]*PostNotificationSettings, error)
	UpdateNotificationSettings(ctx context.Context, postID, userID string, params UpdatePostNotificationParams) error
}

type PostMediaInput struct {
	MediaType string
	URL       string
}

type PostService interface {
	CreatePost(ctx context.Context, userID string, bubbleID string, content string, media []PostMediaInput) (*Post, error)
	GetPostByID(ctx context.Context, id, userID string) (*Post, error)
	GetPostsByBubbleID(ctx context.Context, bubbleID, userID string) ([]*Post, error)
	UpdatePost(ctx context.Context, id, userID, content string) (*Post, error)
	DeletePost(ctx context.Context, id, userID string) error
	GetUserNotificationSettings(ctx context.Context, userID string) ([]*PostNotificationSettings, error)
	UpdatePostNotificationSettings(ctx context.Context, postID, userID string, params UpdatePostNotificationParams) error
}
