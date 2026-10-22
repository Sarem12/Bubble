package response

import (
	"bubble-api/internal/domain"
	"strings"
	"time"
)

type UserResponse struct {
	ID                string     `json:"id"`
	Username          string     `json:"username"`
	Type              string     `json:"type"`
	FirstName         string     `json:"first_name"`
	LastName          string     `json:"last_name"`
	FullName          string     `json:"full_name"`
	Bio               string     `json:"bio"`
	ProfilePictureURL string     `json:"profile_picture_url"`
	CreatedAt         time.Time  `json:"created_at"`
	Birthday          *string    `json:"birthday,omitempty"`
	Age               *int       `json:"age,omitempty"`
	LastActiveAt      *time.Time `json:"last_active_at,omitempty"`
}

// PersonResponse is an alias for UserResponse for backwards compatibility.
type PersonResponse = UserResponse

func NewUserResponse(u *domain.User) *UserResponse {
	if u == nil {
		return nil
	}

	var birthdayStr *string
	var age *int
	if !u.Birthday.IsZero() {
		b := u.Birthday.Format("2006-01-02")
		birthdayStr = &b
		now := time.Now()
		a := now.Year() - u.Birthday.Year()
		if now.YearDay() < u.Birthday.YearDay() {
			a--
		}
		if a >= 0 {
			age = &a
		}
	}

	fullName := strings.TrimSpace(u.FirstName + " " + u.LastName)
	if fullName == "" {
		fullName = u.Username
	}

	return &UserResponse{
		ID:                u.ID,
		Username:          u.Username,
		Type:              u.Type,
		FirstName:         u.FirstName,
		LastName:          u.LastName,
		FullName:          fullName,
		Bio:               u.Bio,
		ProfilePictureURL: u.ProfilePictureURL,
		CreatedAt:         u.CreatedAt,
		Birthday:          birthdayStr,
		Age:               age,
		LastActiveAt:      u.LastActiveAt,
	}
}

// NewPersonResponse is an alias for NewUserResponse for backwards compatibility.
func NewPersonResponse(p *domain.Person) *UserResponse {
	return NewUserResponse(p)
}
