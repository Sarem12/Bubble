package response

import (
	"bubble-api/internal/domain"
	"time"
)

type ReplyResponse struct {
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

func NewReplyResponse(r *domain.Reply) *ReplyResponse {
	if r == nil {
		return nil
	}
	reactionCounts := r.ReactionCounts
	if reactionCounts == nil {
		reactionCounts = make(map[string]int)
	}
	return &ReplyResponse{
		ID:                r.ID,
		PostID:            r.PostID,
		UserID:            r.UserID,
		Username:          r.Username,
		FirstName:         r.FirstName,
		LastName:          r.LastName,
		ProfilePictureURL: r.ProfilePictureURL,
		Content:           r.Content,
		ParentReplyID:     r.ParentReplyID,
		ParentUsername:    r.ParentUsername,
		CreatedAt:         r.CreatedAt,
		LikesCount:        r.LikesCount,
		ReactionCounts:    reactionCounts,
		RepliesCount:      r.RepliesCount,
		UserEmoji:         r.UserEmoji,
	}
}

func NewReplyListResponse(replies []*domain.Reply) []*ReplyResponse {
	if replies == nil {
		return []*ReplyResponse{}
	}
	result := make([]*ReplyResponse, 0, len(replies))
	for _, r := range replies {
		result = append(result, NewReplyResponse(r))
	}
	return result
}
