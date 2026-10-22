package service

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"fmt"
	"crypto/rand"
	"math/big"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type otpService struct {
	repo domain.OTPRepository
}

func NewOTPService(repo domain.OTPRepository) domain.OTPService {

	return &otpService{repo: repo}
}

func (s *otpService) SendOTP(ctx context.Context, provider, identifier, purpose string) error {

	// Check if this specific email/phone has requested >30 times today (stops VPN bypassing)
	oneDayAgo := time.Now().Add(-24 * time.Hour)
	count, err := s.repo.CountRecentOTPs(ctx, identifier, oneDayAgo)
	if err != nil {
		return err
	}
	if count >= 30 {
		return errors.New("daily limit reached for this account. please try again tomorrow")
	}

	latest, err := s.repo.GetOTPByIdentifier(ctx, identifier)
	if err == nil && latest != nil {
		elapsed := time.Since(latest.CreatedAt)
		// Reduced from 2 minutes to 30 seconds to allow the "5 times in 10 minutes" rule to actually function without being annoying
		if elapsed < 30*time.Second {
			remainingSeconds := int((30*time.Second - elapsed).Seconds())
			return fmt.Errorf("please wait %d seconds before requesting a new code", remainingSeconds)
		}
	}

	max := big.NewInt(1000000)
	n, _ := rand.Int(rand.Reader, max)
	code := fmt.Sprintf("%06d", n.Int64())

	expiresAt := time.Now().Add(5 * time.Minute)
	err = s.repo.CreateOTP(ctx, provider, identifier, purpose, code, expiresAt)
	if err != nil {
		return err
	}

	fmt.Printf("\n=========================================\n")
	fmt.Printf("MOCK EMAIL SERVICE: Sending OTP to %s for %s\n", identifier, purpose)
	fmt.Printf("Your verification code is: %s\n", code)
	fmt.Printf("=========================================\n\n")

	return nil
}

func (s *otpService) VerifyOTP(ctx context.Context, identifier, code string) (string, error) {
	otp, err := s.repo.GetOTPByIdentifier(ctx, identifier)
	if err != nil {
		return "", errors.New("no active verification code found")
	}

	if time.Now().After(otp.ExpiresAt) {
		return "", errors.New("code has expired")
	}

	if otp.AttemptsLeft <= 0 {
		return "", errors.New("too many incorrect attempts. please request a new code")
	}

	if otp.Code != code {

		_ = s.repo.DecrementAttempts(ctx, otp.ID)
		return "", errors.New("incorrect code")
	}

	_ = s.repo.DeleteOTP(ctx, otp.ID)

	secret := os.Getenv("JWT_SECRET")
	claims := jwt.MapClaims{
		"verified_identifier":	identifier,
		"provider":		otp.Provider,
		"purpose":		otp.Purpose,
		"exp":			time.Now().Add(30 * time.Minute).Unix(),
		"iat":			time.Now().Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func (s *otpService) ValidateVerificationToken(tokenString string) (string, string, string, error) {
	secret := os.Getenv("JWT_SECRET")
	token, err := jwt.Parse(tokenString, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(secret), nil
	})

	if err != nil || !token.Valid {
		return "", "", "", errors.New("invalid or expired verification token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", "", "", errors.New("invalid token claims")
	}

	provider, ok1 := claims["provider"].(string)
	identifier, ok2 := claims["verified_identifier"].(string)
	purpose, ok3 := claims["purpose"].(string)

	if !ok1 || !ok2 || !ok3 {
		return "", "", "", errors.New("missing claims in verification token")
	}

	return provider, identifier, purpose, nil
}
