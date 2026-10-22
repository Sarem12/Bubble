package request

type SendFriendRequest struct {
	TargetUserID string `json:"target_user_id"`
}

type UpdateFriendshipSettingsRequest struct {
	IsBestfriend		*bool		`json:"is_bestfriend,omitempty"`
	IgnoreInFeed		*bool		`json:"ignore_in_feed,omitempty"`
	NotificationState	*string		`json:"notification_state,omitempty"`
	ExceptionBubbles	[]string	`json:"exception_bubbles,omitempty"`
	InviteState		*string		`json:"invite_state,omitempty"`
	InviteExceptionBubbles	[]string	`json:"invite_exception_bubbles,omitempty"`
}
