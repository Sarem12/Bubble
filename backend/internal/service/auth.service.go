package service

import (
	"bubble-api/internal/domain"
	"bubble-api/pkg/utils"
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type authService struct {
	repo          domain.AuthRepository
	userService   domain.UserService
	googleService domain.GoogleService
	tokenService  domain.TokenService
	bubbleService domain.BubbleService
}

func NewAuthService(repo domain.AuthRepository, userService domain.UserService, googleService domain.GoogleService, tokenService domain.TokenService, bubbleService domain.BubbleService) domain.AuthService {
	return &authService{
		repo:          repo,
		userService:   userService,
		googleService: googleService,
		tokenService:  tokenService,
		bubbleService: bubbleService,
	}
}

func (s *authService) generateToken(userID string) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return "", errors.New("JWT_SECRET is not set")
	}

	claims := jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(time.Hour * 72).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

const MinPasswordLength = 10

func (s *authService) RegisterAnAccount(ctx context.Context, username, firstName, lastName, bio, provider, identifier, password, birthday, deviceID, deviceName string) (*domain.Session, string, error) {
	if len(password) < MinPasswordLength {
		return nil, "", fmt.Errorf("password must be at least %d characters long", MinPasswordLength)
	}

	birthdayTime, err := utils.ParseDate(birthday)
	if err != nil {
		return nil, "", errors.New("invalid birthday format, use YYYY-MM-DD")
	}

	user, err := s.userService.CreateUser(ctx, username, firstName, lastName, bio, "", birthdayTime)
	if err != nil {
		return nil, "", err
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, "", err
	}

	err = s.repo.CreateAuthWithProvider(ctx, user.ID, string(hashedPassword), provider, identifier)
	if err != nil {
		s.userService.DeleteUser(ctx, user.ID)
		return nil, "", err
	}

	// Create the personal feed Bubble automatically!
	err = s.bubbleService.CreatePersonBubble(ctx, user.ID, username)
	if err != nil {
		s.userService.DeleteUser(ctx, user.ID)
		return nil, "", err
	}

	return s.LoginToAccount(ctx, provider, identifier, password, deviceID, deviceName)
}

func (s *authService) LoginToAccount(ctx context.Context, provider string, identifier string, password, deviceID, deviceName string) (*domain.Session, string, error) {
	var auth *domain.Auth
	var err error

	if provider == "username" {
		user, pErr := s.userService.GetUserByUsername(ctx, identifier)
		if pErr != nil {
			return nil, "", pErr
		}
		auth, err = s.repo.GetAuthByUserID(ctx, user.ID)
		if err != nil {
			return nil, "", err
		}
	} else {
		auth, err = s.repo.GetAuthByProvider(ctx, provider, identifier)
		if err != nil {
			return nil, "", err
		}
	}

	if err := bcrypt.CompareHashAndPassword([]byte(auth.PasswordHash), []byte(password)); err != nil {
		return nil, "", errors.New("invalid password")
	}

	session := &domain.Session{
		UserID:     auth.UserID,
		DeviceID:   deviceID,
		DeviceName: deviceName,
	}
	if err := s.repo.CreateSession(ctx, session); err != nil {
		return nil, "", err
	}

	sessionToken, err := s.tokenService.GenerateSessionToken(session.ID, auth.UserID)
	if err != nil {
		return nil, "", err
	}

	return session, sessionToken, nil
}

func (s *authService) AddProviderToAnAccount(ctx context.Context, userID string, provider string, identifier string, password string) error {
	auth, err := s.repo.GetAuthByUserID(ctx, userID)
	if err != nil {
		return errors.New("user auth not found")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(auth.PasswordHash), []byte(password)); err != nil {
		return errors.New("invalid password")
	}

	return s.repo.AddProviderToAuth(ctx, auth.ID, provider, identifier)
}

func (s *authService) LoginWithGoogle(ctx context.Context, idToken string, providedUsername, deviceID, deviceName string) (*domain.Session, string, error) {
	gUser, err := s.googleService.VerifyIDToken(ctx, idToken)
	if err != nil {
		return nil, "", err
	}

	auth, err := s.repo.GetAuthByProvider(ctx, "google", gUser.Email)
	if err == nil {
		session := &domain.Session{
			UserID:     auth.UserID,
			DeviceID:   deviceID,
			DeviceName: deviceName,
		}
		if err := s.repo.CreateSession(ctx, session); err != nil {
			return nil, "", err
		}
		sessionToken, err := s.tokenService.GenerateSessionToken(session.ID, auth.UserID)
		return session, sessionToken, err
	}

	if err != nil && !strings.Contains(err.Error(), "not found") {
		return nil, "", err
	}

	username := providedUsername
	if username == "" {
		username = gUser.Name
	}
	if username == "" || len(username) < 3 {
		username = strings.Split(gUser.Email, "@")[0]
		if len(username) < 3 {
			username = username + "user"
		}
	}

	user, err := s.userService.CreateUser(ctx, username, gUser.GivenName, gUser.FamilyName, "Created via Google", gUser.Picture, time.Time{})
	if err != nil {
		return nil, "", err
	}

	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(time.Now().String()), bcrypt.DefaultCost)

	err = s.repo.CreateAuthWithProvider(ctx, user.ID, string(hashedPassword), "google", gUser.Email)
	if err != nil {
		return nil, "", err
	}

	session := &domain.Session{
		UserID:     user.ID,
		DeviceID:   deviceID,
		DeviceName: deviceName,
	}
	if err := s.repo.CreateSession(ctx, session); err != nil {
		return nil, "", err
	}
	sessionToken, err := s.tokenService.GenerateSessionToken(session.ID, user.ID)
	return session, sessionToken, err
}

func (s *authService) DeleteAccount(ctx context.Context, userID string, password string) error {
	auth, err := s.repo.GetAuthByUserID(ctx, userID)
	if err != nil {
		return errors.New("could not find auth record")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(auth.PasswordHash), []byte(password)); err != nil {
		return errors.New("invalid password")
	}

	return s.userService.DeleteUser(ctx, userID)
}

func (s *authService) ChangePassword(ctx context.Context, userID string, oldPassword string, newPassword string) error {
	auth, err := s.repo.GetAuthByUserID(ctx, userID)
	if err != nil {
		return errors.New("could not find auth record")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(auth.PasswordHash), []byte(oldPassword)); err != nil {
		return errors.New("invalid old password")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	return s.repo.UpdatePassword(ctx, auth.ID, string(hashedPassword))
}

func (s *authService) GetUserSessions(ctx context.Context, userID string) ([]*domain.Session, error) {
	return s.repo.GetUserSessions(ctx, userID)
}

func (s *authService) RevokeSession(ctx context.Context, userID, sessionID string) error {
	return s.repo.DeleteUserSession(ctx, userID, sessionID)
}

func (s *authService) ResetPassword(ctx context.Context, provider, identifier, newPassword string) error {
	if len(newPassword) < MinPasswordLength {
		return fmt.Errorf("password must be at least %d characters long", MinPasswordLength)
	}

	auth, err := s.repo.GetAuthByProvider(ctx, provider, identifier)
	if err != nil {
		return errors.New("user not found")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	return s.repo.UpdatePassword(ctx, auth.ID, string(hashedPassword))
}

func (s *authService) CheckAccountExists(ctx context.Context, provider, identifier string) (bool, error) {
	_, err := s.repo.GetAuthByProvider(ctx, provider, identifier)
	if err != nil {
		// pgx returns "no rows in result set", but our repository overrides it to "auth record not found"
		if strings.Contains(err.Error(), "no rows") || strings.Contains(err.Error(), "not found") {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

func (s *authService) VerifySession(ctx context.Context, sessionToken, deviceID, deviceName string) (string, error) {
	sessionID, userID, err := s.tokenService.ValidateSessionToken(sessionToken)
	if err != nil {
		return "", err
	}

	session, err := s.repo.GetSession(ctx, sessionID)
	if err != nil {
		return "", errors.New("session not found or expired")
	}

	if session.DeviceID != deviceID {
		return "", errors.New("device ID mismatch")
	}
	if session.UserID != userID {
		return "", errors.New("user ID mismatch")
	}

	if session.DeviceName != deviceName {
		_ = s.repo.UpdateSessionLastActive(ctx, sessionID, deviceName)
	} else {
		_ = s.repo.UpdateSessionLastActive(ctx, sessionID, session.DeviceName)
	}

	// Generate the short-lived access token
	accessToken, err := s.tokenService.GenerateToken(session.UserID)
	if err != nil {
		return "", err
	}

	return accessToken, nil
}
