package request

type CreateReplyRequest struct {
	Content		string	`json:"content"`
	ParentReplyID	*string	`json:"parent_reply_id,omitempty"`
}

type UpdateReplyRequest struct {
	Content string `json:"content"`
}

type ReactToReplyRequest struct {
	EmojiType string `json:"emoji_type"`
}
