package domain

import (
	"context"
	"time"
)

type TopComment struct {
	ID                string    `json:"id"`
	PostID            string    `json:"post_id"`
	UserID            string    `json:"user_id"`
	Username          string    `json:"username"`
	FirstName         string    `json:"first_name"`
	LastName          string    `json:"last_name"`
	ProfilePictureURL string    `json:"profile_picture_url"`
	Content           string    `json:"content"`
	CreatedAt         time.Time `json:"created_at"`
	LikesCount        int       `json:"likes_count"`
	RepliesCount      int       `json:"replies_count"`
}

type FeedItem struct {
	ID             string         `json:"id"`
	Content        string         `json:"content"`
	CreatedAt      time.Time      `json:"created_at"`
	AuthorID        string         `json:"author_id"`
	AuthorUsername  string         `json:"author_username"`
	AuthorFirstName string         `json:"author_first_name"`
	AuthorLastName  string         `json:"author_last_name"`
	AuthorPicture   string         `json:"author_profile_picture_url"`
	BubbleID       string         `json:"bubble_id"`
	BubbleName     string         `json:"bubble_name"`
	LikesCount     int            `json:"likes_count"`
	ReactionCounts map[string]int `json:"reaction_counts"`
	RepliesCount   int            `json:"replies_count"`
	UserEmoji      *string        `json:"user_emoji"`
	Media          []*PostMedia   `json:"media"`
	TopComment     *TopComment    `json:"top_comment,omitempty"`
}

type FeedRepository interface {
	GetFeed(ctx context.Context, userID string, cursorTime time.Time, cursorID string, limit int) ([]*FeedItem, error)
	GetFeedItem(ctx context.Context, userID, postID string) (*FeedItem, error)
	GetExploreFeed(ctx context.Context, userID string, limit int) ([]*FeedItem, error)
	GetUserFeed(ctx context.Context, requestingUserID, targetUserID string, limit int) ([]*FeedItem, error)
}

type FeedService interface {
	GetFeed(ctx context.Context, userID string, cursorStr string, limit int) ([]*FeedItem, error)
	GetFeedItem(ctx context.Context, userID, postID string) (*FeedItem, error)
	GetExploreFeed(ctx context.Context, userID string, limit int) ([]*FeedItem, error)
	GetUserFeed(ctx context.Context, requestingUserID, targetUserID string, limit int) ([]*FeedItem, error)
}
