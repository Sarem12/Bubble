package request

type CreatePostRequest struct {
	BubbleID  *string          `json:"bubble_id"`
	BubbleIDs []string         `json:"bubble_ids"`
	Content   string           `json:"content"`
	Media     []PostMediaInput `json:"media,omitempty"`
}

type UpdatePostRequest struct {
	Content  string `json:"content"`
	MediaURL string `json:"media_url,omitempty"`
}

type UpdatePostNotificationRequest struct {
	Reactions *string `json:"reactions_notification" validate:"omitempty,oneof=AUTOMATIC ON OFF"`
	Comments  *string `json:"comments_notification" validate:"omitempty,oneof=AUTOMATIC ON OFF"`
	Replies   *string `json:"replies_notification" validate:"omitempty,oneof=AUTOMATIC ON OFF"`
}

type PostMediaInput struct {
	MediaType string `json:"media_type"`
	URL       string `json:"url"`
}
