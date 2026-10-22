package service

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"strings"
)

type mockGoogleService struct{}

func NewMockGoogleService() domain.GoogleService {
	return &mockGoogleService{}
}

func (s *mockGoogleService) VerifyIDToken(ctx context.Context, token string) (*domain.GoogleUser, error) {

	normalizedToken := strings.TrimSpace(token)
	if normalizedToken == "invalid_token" || normalizedToken == "" {
		return nil, errors.New("mock: invalid google id_token")
	}

	email := normalizedToken
	if !strings.Contains(email, "@") {
		email = normalizedToken + "@gmail.com"
	}

	name := strings.Split(email, "@")[0]

	return &domain.GoogleUser{
		Email:	email,
		Name:	name,
	}, nil
}
