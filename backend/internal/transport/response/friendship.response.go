package response

import (
	"bubble-api/internal/domain"
	"time"
)

type FriendshipResponse struct {
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

func NewFriendshipResponse(f *domain.Friendship) *FriendshipResponse {
	if f == nil {
		return nil
	}
	eb := f.ExceptionBubbles
	if eb == nil {
		eb = []string{}
	}
	ieb := f.InviteExceptionBubbles
	if ieb == nil {
		ieb = []string{}
	}
	return &FriendshipResponse{
		SourceUserID:           f.SourceUserID,
		TargetUserID:           f.TargetUserID,
		State:                  f.State,
		IsBestfriend:           f.IsBestfriend,
		IgnoreInFeed:           f.IgnoreInFeed,
		NotificationState:      f.NotificationState,
		ExceptionBubbles:       eb,
		InviteState:            f.InviteState,
		InviteExceptionBubbles: ieb,
		CreatedAt:              f.CreatedAt,
		UpdatedAt:              f.UpdatedAt,
	}
}

func NewFriendshipListResponse(fs []*domain.Friendship) []*FriendshipResponse {
	if fs == nil {
		return []*FriendshipResponse{}
	}
	result := make([]*FriendshipResponse, 0, len(fs))
	for _, f := range fs {
		result = append(result, NewFriendshipResponse(f))
	}
	return result
}
