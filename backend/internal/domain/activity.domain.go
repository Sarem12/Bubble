package domain

import (
	"context"
	"time"
)

type ActivityItem struct {
	ID             string    `json:"id"`
	Type           string    `json:"type"` // post_reaction, post_reply, comment_reply, reply_reaction, friend_request, friend_accepted
	ActorID        string    `json:"actor_id"`
	ActorUsername  string    `json:"actor_username"`
	ActorFirstName string    `json:"actor_first_name"`
	ActorLastName  string    `json:"actor_last_name"`
	ActorAvatar    string    `json:"actor_avatar"`
	PostID         *string   `json:"post_id,omitempty"`
	PostContent    *string   `json:"post_content,omitempty"`
	PostMediaURL   *string   `json:"post_media_url,omitempty"`
	ReplyID        *string   `json:"reply_id,omitempty"`
	ReplyContent   *string   `json:"reply_content,omitempty"`
	ParentReplyID  *string   `json:"parent_reply_id,omitempty"`
	Emoji          *string   `json:"emoji,omitempty"`
	State          *string   `json:"state,omitempty"`
	CreatedAt      time.Time `json:"created_at"`
}

type FriendRequestItem struct {
	ID                string    `json:"id"`
	UserID            string    `json:"user_id"`
	Username          string    `json:"username"`
	FirstName         string    `json:"first_name"`
	LastName          string    `json:"last_name"`
	ProfilePictureURL string    `json:"profile_picture_url"`
	CreatedAt         time.Time `json:"created_at"`
}

type ActivityFeedResponse struct {
	Activities     []*ActivityItem      `json:"activities"`
	FriendRequests []*FriendRequestItem `json:"friend_requests"`
}

type ActivityRepository interface {
	GetActivities(ctx context.Context, userID string, limit int, offset int) ([]*ActivityItem, error)
	GetPendingFriendRequests(ctx context.Context, userID string) ([]*FriendRequestItem, error)
}

type ActivityService interface {
	GetActivityFeed(ctx context.Context, userID string, limit int, offset int) (*ActivityFeedResponse, error)
	GetPendingFriendRequests(ctx context.Context, userID string) ([]*FriendRequestItem, error)
}
