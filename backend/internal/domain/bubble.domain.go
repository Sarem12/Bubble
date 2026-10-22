package domain

import (
	"context"
	"time"
)

type Bubble struct {
	ID                   string    `json:"id"`
	Name                 string    `json:"name"`
	Description          string    `json:"description"`
	Type                 string    `json:"type"`
	OwnerID              *string   `json:"owner_id,omitempty"`
	MemberKey            *string   `json:"member_key,omitempty"`
	CreatedAt            time.Time `json:"created_at"`
	NotificationsEnabled *bool     `json:"notifications_enabled,omitempty"`
}

type BubbleMember struct {
	UserID               string    `json:"user_id"`
	BubbleID             string    `json:"bubble_id"`
	Role                 string    `json:"role"`
	NotificationsEnabled bool      `json:"notifications_enabled"`
	JoinedAt             time.Time `json:"joined_at"`
}

type BubbleInvitation struct {
	ID        string    `json:"id"`
	BubbleID  string    `json:"bubble_id"`
	InviterID string    `json:"inviter_id"`
	InviteeID string    `json:"invitee_id"`
	Status    string    `json:"status"`
	CreatedAt time.Time `json:"created_at"`
}
type BubbleRepository interface {
	Join(ctx context.Context, member *BubbleMember) error
	Leave(ctx context.Context, userID, bubbleID string) error
	GetMembers(ctx context.Context, bubbleID string) ([]*BubbleMember, error)
	CheckMembership(ctx context.Context, userID, bubbleID string) (bool, error)
	CreateInvitation(ctx context.Context, invite *BubbleInvitation) error
	GetInvitation(ctx context.Context, inviteID string) (*BubbleInvitation, error)
	UpdateInvitationStatus(ctx context.Context, inviteID, status string) error
	AcceptInvitationAndJoin(ctx context.Context, inviteID, userID, bubbleID string) error

	Create(ctx context.Context, bubble *Bubble) error
	GetByID(ctx context.Context, id string) (*Bubble, error)
	GetByName(ctx context.Context, name string) (*Bubble, error)
	GetPersonBubbleByOwnerID(ctx context.Context, ownerID string) (*Bubble, error)
	GetBubbles(ctx context.Context, nameFilter string, sortBy string, limit int) ([]*Bubble, error)
	GetUserBubbles(ctx context.Context, targetUserID string, isSelf bool) ([]*Bubble, error)
	UpdateMemberNotifications(ctx context.Context, userID, bubbleID string, enabled bool) error
	Update(ctx context.Context, bubble *Bubble) error
	Delete(ctx context.Context, id string) error
}

type BubbleService interface {
	JoinBubble(ctx context.Context, userID, bubbleID string, memberKey *string) error
	JoinPersonBubble(ctx context.Context, userID, bubbleID string) error
	LeaveBubble(ctx context.Context, userID, bubbleID string) error
	GetBubbleMembers(ctx context.Context, bubbleID string) ([]*BubbleMember, error)
	CheckMembership(ctx context.Context, userID, bubbleID string) (bool, error)
	InviteToBubble(ctx context.Context, inviterID, inviteeID, bubbleID string) error
	AcceptInvitation(ctx context.Context, inviteeID, inviteID string) error
	DeclineInvitation(ctx context.Context, inviteeID, inviteID string) error

	CreateBubble(ctx context.Context, name string, description string, bubbleType string, ownerID string, memberKey string) (*Bubble, error)
	GetBubbleByID(ctx context.Context, id string) (*Bubble, error)
	GetBubbleByName(ctx context.Context, name string) (*Bubble, error)
	GetPersonBubbleByOwnerID(ctx context.Context, ownerID string) (*Bubble, error)
	GetBubbles(ctx context.Context, nameFilter string, sortBy string, limit int) ([]*Bubble, error)
	GetUserBubbles(ctx context.Context, targetUserID string, isSelf bool) ([]*Bubble, error)
	UpdateMemberNotifications(ctx context.Context, userID, bubbleID string, enabled bool) error
	DeleteBubble(ctx context.Context, id string) error
	CreatePersonBubble(ctx context.Context, userID, username string) error
}
