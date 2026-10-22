package response

import (
	"bubble-api/internal/domain"
	"time"
)

type PostInteractionResponse struct {
	UserID		string		`json:"user_id"`
	PostID		string		`json:"post_id"`
	EmojiType	*string		`json:"emoji_type"`
	IsSaved		bool		`json:"is_saved"`
	LastViewedAt	*time.Time	`json:"last_viewed_at"`
	CreatedAt	time.Time	`json:"created_at"`
	UpdatedAt	time.Time	`json:"updated_at"`
}

func NewPostInteractionResponse(i *domain.PostInteraction) *PostInteractionResponse {
	if i == nil {
		return nil
	}
	return &PostInteractionResponse{
		UserID:		i.UserID,
		PostID:		i.PostID,
		EmojiType:	i.EmojiType,
		IsSaved:	i.IsSaved,
		LastViewedAt:	i.LastViewedAt,
		CreatedAt:	i.CreatedAt,
		UpdatedAt:	i.UpdatedAt,
	}
}

func NewPostInteractionListResponse(interactions []*domain.PostInteraction) []*PostInteractionResponse {
	if interactions == nil {
		return []*PostInteractionResponse{}
	}
	result := make([]*PostInteractionResponse, 0, len(interactions))
	for _, i := range interactions {
		result = append(result, NewPostInteractionResponse(i))
	}
	return result
}
