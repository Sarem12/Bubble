package domain

import (
	"context"
	"time"
)

type Auth struct {
	ID           string    `json:"id"`
	UserID       string    `json:"user_id"`
	PasswordHash string    `json:"password_hash"`
	CreatedAt    time.Time `json:"created_at"`
}

type AuthProvider struct {
	ID         string    `json:"id"`
	AuthID     string    `json:"auth_id"`
	Provider   string    `json:"provider"`
	Identifier string    `json:"identifier"`
	CreatedAt  time.Time `json:"created_at"`
}

type AuthRepository interface {
	CreateAuthWithProvider(ctx context.Context, userID, passwordHash, provider, identifier string) error
	AddProviderToAuth(ctx context.Context, authID, provider, identifier string) error
	GetAuthByProvider(ctx context.Context, provider, identifier string) (*Auth, error)
	GetAuthByUserID(ctx context.Context, userID string) (*Auth, error)
	UpdatePassword(ctx context.Context, authID, newPasswordHash string) error

	CreateSession(ctx context.Context, session *Session) error
	GetSession(ctx context.Context, sessionID string) (*Session, error)
	UpdateSessionLastActive(ctx context.Context, sessionID, deviceName string) error
	DeleteSession(ctx context.Context, sessionID string) error
	GetUserSessions(ctx context.Context, userID string) ([]*Session, error)
	DeleteUserSession(ctx context.Context, userID, sessionID string) error
}

type AuthService interface {
	VerifySession(ctx context.Context, sessionToken, deviceID, deviceName string) (string, error)

	RegisterAnAccount(ctx context.Context, username, firstName, lastName, bio, provider, identifier, password, birthday, deviceID, deviceName string) (*Session, string, error)
	LoginToAccount(ctx context.Context, provider string, identifier string, password, deviceID, deviceName string) (*Session, string, error)
	AddProviderToAnAccount(ctx context.Context, userID, provider, identifier, password string) error
	LoginWithGoogle(ctx context.Context, idToken string, providedUsername, deviceID, deviceName string) (*Session, string, error)
	DeleteAccount(ctx context.Context, userID, password string) error
	ResetPassword(ctx context.Context, provider, identifier, newPassword string) error
	ChangePassword(ctx context.Context, userID, oldPassword, newPassword string) error
	GetUserSessions(ctx context.Context, userID string) ([]*Session, error)
	RevokeSession(ctx context.Context, userID, sessionID string) error
	CheckAccountExists(ctx context.Context, provider, identifier string) (bool, error)
}

type TokenService interface {
	GenerateToken(userID string) (string, error)
	GenerateSessionToken(sessionID, userID string) (string, error)
	ValidateSessionToken(token string) (string, string, error)
	ValidateToken(tokenString string) (string, error)
}

type Session struct {
	ID           string    `json:"id"`
	UserID       string    `json:"user_id"`
	DeviceID     string    `json:"device_id"`
	DeviceName   string    `json:"device_name"`
	CreatedAt    time.Time `json:"created_at"`
	LastActiveAt time.Time `json:"last_active_at"`
}
