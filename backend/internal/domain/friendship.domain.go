package domain

import (
	"context"
	"time"
)

type Friendship struct {
	SourceUserID           string    `json:"source_user_id"`
	TargetUserID           string    `json:"target_user_id"`
	State                  string    `json:"state"`
	IsBestfriend           bool      `json:"is_bestfriend"`
	IgnoreInFeed           bool      `json:"ignore_in_feed"`
	NotificationState      string    `json:"notification_state"`
	ExceptionBubbles       []string  `json:"exception_bubbles"`
	InviteState            string    `json:"invite_state"`
	InviteExceptionBubbles []string  `json:"invite_exception_bubbles"`
	CreatedAt              time.Time `json:"created_at"`
	UpdatedAt              time.Time `json:"updated_at"`
}

type FriendshipRepository interface {
	Upsert(ctx context.Context, f *Friendship) (*Friendship, error)
	Get(ctx context.Context, sourceID, targetID string) (*Friendship, error)
	GetByState(ctx context.Context, sourceID, state string) ([]*Friendship, error)
	Delete(ctx context.Context, sourceID, targetID string) error
	DeleteMutual(ctx context.Context, user1, user2 string) error
	UpsertMutual(ctx context.Context, f1, f2 *Friendship) error
	BlockUserAtomic(ctx context.Context, blockF *Friendship, reverseTarget, reverseSource string) error
}

type FriendshipService interface {
	SendRequest(ctx context.Context, sourceID, targetID string) error
	AcceptRequest(ctx context.Context, targetID, sourceID string) error
	DeclineRequest(ctx context.Context, targetID, sourceID string) error
	BlockUser(ctx context.Context, sourceID, targetID string) error
	UnblockUser(ctx context.Context, sourceID, targetID string) error
	RemoveFriend(ctx context.Context, sourceID, targetID string) error

	UpdateSettings(ctx context.Context, sourceID, targetID string, isBestfriend *bool, ignoreInFeed *bool, notifState *string, exceptions []string, inviteState *string, inviteExceptions []string) (*Friendship, error)
	GetRequests(ctx context.Context, userID string) ([]*Friendship, error)
	GetFriends(ctx context.Context, userID string) ([]*Friendship, error)
	GetBlocked(ctx context.Context, userID string) ([]*Friendship, error)
}
