package domain

import (
	"context"
	"time"
)

type User struct {
	ID                string     `json:"id"`
	Username          string     `json:"username"`
	Type              string     `json:"type"`
	FirstName         string     `json:"first_name"`
	LastName          string     `json:"last_name"`
	Bio               string     `json:"bio"`
	ProfilePictureURL string     `json:"profile_picture_url"`
	CreatedAt         time.Time  `json:"created_at"`
	Birthday          time.Time  `json:"birthday"`
	LastActiveAt      *time.Time `json:"last_active_at,omitempty"`
}

// Person is an alias for User to preserve backwards compatibility.
type Person = User

type UserSettings struct {
	UserID                      string   `json:"user_id"`
	NotificationState           string   `json:"notification_state"`
	InvitationState             string   `json:"invitation_state"`
	GlobalReactionNotifications string   `json:"global_reaction_notifications"`
	GlobalCommentNotifications  string   `json:"global_comment_notifications"`
	GlobalReplyNotifications    string   `json:"global_reply_notifications"`
	MessageNotifications        string   `json:"message_notifications"`
	AllowNewChats               string   `json:"allow_new_chats"`
	TopReactions                []string `json:"top_reactions"`
}

type UpdateSettingsParams struct {
	NotificationState           *string
	InvitationState             *string
	GlobalReactionNotifications *string
	GlobalCommentNotifications  *string
	GlobalReplyNotifications    *string
	MessageNotifications        *string
	AllowNewChats               *string
	TopReactions                []string
}

type UserRepository interface {
	GetSettings(ctx context.Context, userID string) (*UserSettings, error)
	UpdateSettings(ctx context.Context, userID string, params UpdateSettingsParams) (*UserSettings, error)

	Create(ctx context.Context, user *User) error
	GetByID(ctx context.Context, id string) (*User, error)
	GetByUsername(ctx context.Context, username string) (*User, error)

	Update(ctx context.Context, user *User) error
	Delete(ctx context.Context, id string) error
	UpdateLastActive(ctx context.Context, id string, lastActive time.Time) error
	UpdateProfilePicture(ctx context.Context, id, pictureURL string) error
}

// PersonRepository is an alias for UserRepository.
type PersonRepository = UserRepository

type UserService interface {
	CreateUser(ctx context.Context, username, firstName, lastName, bio, profilePictureURL string, birthday time.Time) (*User, error)
	GetUserByID(ctx context.Context, id string) (*User, error)
	GetUserByUsername(ctx context.Context, username string) (*User, error)
	UpdateUser(ctx context.Context, id, username, firstName, lastName, bio, profilePictureURL, userType string, birthday time.Time) (*User, error)
	UpdateSettings(ctx context.Context, userID string, params UpdateSettingsParams) (*UserSettings, error)
	GetSettings(ctx context.Context, userID string) (*UserSettings, error)
	DeleteUser(ctx context.Context, id string) error
	UpdateLastActive(ctx context.Context, id string, lastActive time.Time) error
	UpdateProfilePicture(ctx context.Context, id, pictureURL string) error

	// Compatibility methods
	CreatePerson(ctx context.Context, username, firstName, lastName, bio, profilePictureURL string, birthday time.Time) (*Person, error)
	GetPersonByID(ctx context.Context, id string) (*Person, error)
	GetPersonByUsername(ctx context.Context, username string) (*Person, error)
	UpdatePerson(ctx context.Context, id, username, firstName, lastName, bio, profilePictureURL, userType string, birthday time.Time) (*Person, error)
	DeletePerson(ctx context.Context, id string) error
}

// PersonService is an alias for UserService.
type PersonService = UserService
