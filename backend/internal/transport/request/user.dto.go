package request

type CreateUserRequest struct {
	Username          string `json:"username"`
	FirstName         string `json:"first_name"`
	LastName          string `json:"last_name"`
	Bio               string `json:"bio"`
	ProfilePictureURL string `json:"profile_picture_url"`
	Birthday          string `json:"birthday"`
}

// CreatePersonRequest is an alias for CreateUserRequest for backwards compatibility.
type CreatePersonRequest = CreateUserRequest

type UpdateUserRequest struct {
	Username          string `json:"username"`
	Type              string `json:"type" validate:"omitempty,oneof=PUBLIC PRIVATE"`
	FirstName         string `json:"first_name"`
	LastName          string `json:"last_name"`
	Bio               string `json:"bio"`
	ProfilePictureURL string `json:"profile_picture_url"`
	Birthday          string `json:"birthday"`
}

// UpdatePersonRequest is an alias for UpdateUserRequest for backwards compatibility.
type UpdatePersonRequest = UpdateUserRequest

type UpdateUserSettingsRequest struct {
	NotificationState           *string  `json:"notification_state" validate:"omitempty,oneof=AUTOMATIC ON OFF"`
	InvitationState             *string  `json:"invitation_state" validate:"omitempty,oneof=AUTOMATIC ON OFF"`
	GlobalReactionNotifications *string  `json:"global_reaction_notifications" validate:"omitempty,oneof=EVERYONE FRIENDS BUBBLE_MEMBERS FRIENDS_AND_BUBBLES BEST_FRIENDS BEST_FRIENDS_AND_BUBBLES NOBODY"`
	GlobalCommentNotifications  *string  `json:"global_comment_notifications" validate:"omitempty,oneof=EVERYONE FRIENDS BUBBLE_MEMBERS FRIENDS_AND_BUBBLES BEST_FRIENDS BEST_FRIENDS_AND_BUBBLES NOBODY"`
	GlobalReplyNotifications    *string  `json:"global_reply_notifications" validate:"omitempty,oneof=EVERYONE FRIENDS BUBBLE_MEMBERS FRIENDS_AND_BUBBLES BEST_FRIENDS BEST_FRIENDS_AND_BUBBLES NOBODY"`
	MessageNotifications        *string  `json:"message_notifications" validate:"omitempty,oneof=ALL_FRIENDS BEST_FRIENDS NOBODY"`
	AllowNewChats               *string  `json:"allow_new_chats" validate:"omitempty,oneof=ALL_FRIENDS BEST_FRIENDS NOBODY"`
	TopReactions                []string `json:"top_reactions" validate:"omitempty,max=5,dive,max=16"`
}
