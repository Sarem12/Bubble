package ws

type ChatPayload struct {
	Action         string `json:"action"`
	ConversationID string `json:"conversation_id"`
	RecipientID    string `json:"recipient_id"`
	Content        string `json:"content"`
	Topic          string `json:"topic,omitempty"`
	MessageID      string `json:"message_id,omitempty"`
	Emoji          string `json:"emoji,omitempty"`
	ClientID       string `json:"client_id,omitempty"`
}
