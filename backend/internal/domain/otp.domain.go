package domain

import (
	"context"
	"time"
)

type OTPCode struct {
	ID		string		`json:"id"`
	Provider	string		`json:"provider"`
	Identifier	string		`json:"identifier"`
	Purpose		string		`json:"purpose"`
	Code		string		`json:"-"`
	AttemptsLeft	int		`json:"attempts_left"`
	ExpiresAt	time.Time	`json:"expires_at"`
	CreatedAt	time.Time	`json:"created_at"`
}

type OTPRepository interface {
	CreateOTP(ctx context.Context, provider, identifier, purpose, code string, expiresAt time.Time) error
	GetOTPByIdentifier(ctx context.Context, identifier string) (*OTPCode, error)
	DecrementAttempts(ctx context.Context, id string) error
	DeleteOTP(ctx context.Context, id string) error
	DeleteExpiredOTPs(ctx context.Context) error
	CountRecentOTPs(ctx context.Context, identifier string, since time.Time) (int, error)
}

type OTPService interface {
	SendOTP(ctx context.Context, provider, identifier, purpose string) error
	VerifyOTP(ctx context.Context, identifier, code string) (string, error)
	ValidateVerificationToken(tokenString string) (provider string, identifier string, purpose string, err error)
}
