package request

type ReactToPostRequest struct {
	EmojiType string `json:"emoji_type"`
}

type SavePostRequest struct {
	IsSaved bool `json:"is_saved"`
}
