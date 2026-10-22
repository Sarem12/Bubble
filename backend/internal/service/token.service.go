package service

import (
	"bubble-api/internal/domain"
	"errors"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type tokenService struct{}

func NewTokenService() domain.TokenService {
	return &tokenService{}
}

func (s *tokenService) GenerateToken(userID string) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return "", errors.New("JWT_SECRET is not set")
	}

	claims := jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(time.Hour * 1).Unix(), // Short-lived access token
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func (s *tokenService) ValidateToken(tokenString string) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return "", errors.New("JWT_SECRET is not set")
	}

	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(secret), nil
	})

	if err != nil || !token.Valid {
		return "", errors.New("invalid or expired access token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", errors.New("invalid token claims")
	}

	userID, ok := claims["user_id"].(string)
	if !ok {
		return "", errors.New("user ID not found in token")
	}

	return userID, nil
}

func (s *tokenService) GenerateSessionToken(sessionID, userID string) (string, error) {
	secret := os.Getenv("JWT_REFRESH_SECRET")
	if secret == "" {
		secret = os.Getenv("JWT_SECRET") // fallback
	}

	claims := jwt.MapClaims{
		"session_id": sessionID,
		"user_id":    userID,
		"exp":        time.Now().Add(time.Hour * 24 * 30).Unix(), // 30 days
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func (s *tokenService) ValidateSessionToken(tokenString string) (string, string, error) {
	secret := os.Getenv("JWT_REFRESH_SECRET")
	if secret == "" {
		secret = os.Getenv("JWT_SECRET") // fallback
	}

	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(secret), nil
	})

	if err != nil || !token.Valid {
		return "", "", errors.New("invalid or expired session token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", "", errors.New("invalid token claims")
	}

	sessionID, ok := claims["session_id"].(string)
	if !ok {
		return "", "", errors.New("session ID not found in token")
	}
	
	userID, ok := claims["user_id"].(string)
	if !ok {
		return "", "", errors.New("user ID not found in token")
	}

	return sessionID, userID, nil
}
