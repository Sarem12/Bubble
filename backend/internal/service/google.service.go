package service

import (
	"context"
	"errors"
	"os"

	"bubble-api/internal/domain"

	"google.golang.org/api/idtoken"
)

type googleService struct {
	clientID string
}

func NewGoogleService() domain.GoogleService {
	return &googleService{
		clientID: os.Getenv("GOOGLE_CLIENT_ID"),
	}
}

func (s *googleService) VerifyIDToken(ctx context.Context, token string) (*domain.GoogleUser, error) {
	if s.clientID == "" {
		return nil, errors.New("GOOGLE_CLIENT_ID is not set")
	}

	payload, err := idtoken.Validate(ctx, token, s.clientID)
	if err != nil {
		return nil, err
	}

	email, _ := payload.Claims["email"].(string)
	name, _ := payload.Claims["name"].(string)
	givenName, _ := payload.Claims["given_name"].(string)
	familyName, _ := payload.Claims["family_name"].(string)
	picture, _ := payload.Claims["picture"].(string)

	return &domain.GoogleUser{
		Email:		email,
		Name:		name,
		GivenName:	givenName,
		FamilyName:	familyName,
		Picture:	picture,
	}, nil
}
