package response

import (
	"bubble-api/internal/domain"
	"time"
)

type BubbleResponse struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
}

func NewBubbleResponse(b *domain.Bubble) *BubbleResponse {
	if b == nil {
		return nil
	}
	return &BubbleResponse{
		ID:          b.ID,
		Name:        b.Name,
		Description: b.Description,
		CreatedAt:   b.CreatedAt,
	}
}

func NewBubbleListResponse(bubbles []*domain.Bubble) []*BubbleResponse {
	if bubbles == nil {
		return []*BubbleResponse{}
	}
	result := make([]*BubbleResponse, 0, len(bubbles))
	for _, b := range bubbles {
		result = append(result, NewBubbleResponse(b))
	}
	return result
}
