package service

import (
	"context"
	"errors"
	"strings"
	"time"

	"bubble-api/internal/domain"
)

type userService struct {
	repo domain.UserRepository
}

func NewUserService(repo domain.UserRepository) domain.UserService {
	return &userService{
		repo: repo,
	}
}

// NewPersonService is an alias constructor for backwards compatibility.
func NewPersonService(repo domain.UserRepository) domain.UserService {
	return NewUserService(repo)
}

func (s *userService) CreateUser(ctx context.Context, username, firstName, lastName, bio, profilePictureURL string, birthday time.Time) (*domain.User, error) {
	username = strings.TrimSpace(strings.ToLower(username))

	if len(username) < 3 {
		return nil, errors.New("username must be at least 3 characters")
	}

	user := &domain.User{
		Username:          username,
		Type:              "PUBLIC",
		FirstName:         firstName,
		LastName:          lastName,
		Bio:               bio,
		ProfilePictureURL: profilePictureURL,
		Birthday:          birthday,
	}

	err := s.repo.Create(ctx, user)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func (s *userService) CreatePerson(ctx context.Context, username, firstName, lastName, bio, profilePictureURL string, birthday time.Time) (*domain.Person, error) {
	return s.CreateUser(ctx, username, firstName, lastName, bio, profilePictureURL, birthday)
}

func (s *userService) GetUserByID(ctx context.Context, id string) (*domain.User, error) {
	if id == "" {
		return nil, errors.New("id cannot be empty")
	}
	return s.repo.GetByID(ctx, id)
}

func (s *userService) GetPersonByID(ctx context.Context, id string) (*domain.Person, error) {
	return s.GetUserByID(ctx, id)
}

func (s *userService) UpdateUser(ctx context.Context, id, username, firstName, lastName, bio, profilePictureURL, userType string, birthday time.Time) (*domain.User, error) {
	if id == "" {
		return nil, errors.New("id cannot be empty")
	}
	username = strings.TrimSpace(strings.ToLower(username))
	if len(username) < 3 {
		return nil, errors.New("username must be at least 3 characters")
	}

	user, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	user.Username = username
	user.FirstName = firstName
	user.LastName = lastName
	user.Bio = bio
	user.ProfilePictureURL = profilePictureURL
	user.Birthday = birthday
	if userType != "" {
		if userType != "PUBLIC" && userType != "PRIVATE" {
			return nil, errors.New("account visibility must be PUBLIC or PRIVATE")
		}
		user.Type = userType
	}

	if err := s.repo.Update(ctx, user); err != nil {
		return nil, err
	}
	return user, nil
}

func (s *userService) UpdatePerson(ctx context.Context, id, username, firstName, lastName, bio, profilePictureURL, userType string, birthday time.Time) (*domain.Person, error) {
	return s.UpdateUser(ctx, id, username, firstName, lastName, bio, profilePictureURL, userType, birthday)
}

func (s *userService) UpdateSettings(ctx context.Context, userID string, params domain.UpdateSettingsParams) (*domain.UserSettings, error) {
	validTriState := func(val *string) bool {
		if val == nil {
			return true
		}
		v := *val
		return v == "AUTOMATIC" || v == "ON" || v == "OFF"
	}
	validAudience := func(val *string) bool {
		if val == nil {
			return true
		}
		v := *val
		return v == "EVERYONE" || v == "FRIENDS" || v == "BUBBLE_MEMBERS" || v == "FRIENDS_AND_BUBBLES" || v == "BEST_FRIENDS" || v == "BEST_FRIENDS_AND_BUBBLES" || v == "NOBODY"
	}
	validChat := func(val *string) bool {
		if val == nil {
			return true
		}
		v := *val
		return v == "ALL_FRIENDS" || v == "BEST_FRIENDS" || v == "NOBODY"
	}

	if !validTriState(params.NotificationState) || !validTriState(params.InvitationState) {
		return nil, errors.New("invalid tri-state value")
	}
	if !validAudience(params.GlobalReactionNotifications) || !validAudience(params.GlobalCommentNotifications) || !validAudience(params.GlobalReplyNotifications) {
		return nil, errors.New("invalid audience filter value")
	}
	if !validChat(params.MessageNotifications) || !validChat(params.AllowNewChats) {
		return nil, errors.New("invalid chat permission value")
	}

	return s.repo.UpdateSettings(ctx, userID, params)
}

func (s *userService) GetSettings(ctx context.Context, userID string) (*domain.UserSettings, error) {
	return s.repo.GetSettings(ctx, userID)
}

func (s *userService) DeleteUser(ctx context.Context, id string) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}
	return s.repo.Delete(ctx, id)
}

func (s *userService) DeletePerson(ctx context.Context, id string) error {
	return s.DeleteUser(ctx, id)
}

func (s *userService) GetUserByUsername(ctx context.Context, username string) (*domain.User, error) {
	if username == "" {
		return nil, errors.New("username cannot be empty")
	}
	return s.repo.GetByUsername(ctx, username)
}

func (s *userService) GetPersonByUsername(ctx context.Context, username string) (*domain.Person, error) {
	return s.GetUserByUsername(ctx, username)
}

func (s *userService) UpdateLastActive(ctx context.Context, id string, lastActive time.Time) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}
	return s.repo.UpdateLastActive(ctx, id, lastActive)
}

func (s *userService) UpdateProfilePicture(ctx context.Context, id, pictureURL string) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}
	return s.repo.UpdateProfilePicture(ctx, id, pictureURL)
}
