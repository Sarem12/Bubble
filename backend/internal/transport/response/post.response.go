package response

import (
	"bubble-api/internal/domain"
	"time"
)

type PostResponse struct {
	ID         string    `json:"id"`
	UserID     string    `json:"user_id"`
	BubbleID   string    `json:"bubble_id"`
	BubbleName string    `json:"bubble_name,omitempty"`
	BubbleIDs  []string  `json:"bubble_ids,omitempty"`
	Content    string    `json:"content"`
	CreatedAt  time.Time `json:"created_at"`
}

func NewPostResponse(p *domain.Post) *PostResponse {
	if p == nil {
		return nil
	}
	var bIDs []string
	if len(p.BubbleIDs) > 0 {
		bIDs = p.BubbleIDs
	} else if p.BubbleID != "" {
		bIDs = []string{p.BubbleID}
	}
	return &PostResponse{
		ID:         p.ID,
		UserID:     p.UserID,
		BubbleID:   p.BubbleID,
		BubbleName: p.BubbleName,
		BubbleIDs:  bIDs,
		Content:    p.Content,
		CreatedAt:  p.CreatedAt,
	}
}

func NewPostListResponse(posts []*domain.Post) []*PostResponse {
	if posts == nil {
		return []*PostResponse{}
	}
	result := make([]*PostResponse, 0, len(posts))
	for _, p := range posts {
		result = append(result, NewPostResponse(p))
	}
	return result
}
