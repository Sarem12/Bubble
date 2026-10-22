package domain

import "context"

type GoogleUser struct {
	Email		string
	Name		string
	GivenName	string
	FamilyName	string
	Picture		string
}

type GoogleService interface {
	VerifyIDToken(ctx context.Context, idToken string) (*GoogleUser, error)
}
