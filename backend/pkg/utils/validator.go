package utils

import (
	"regexp"
)

var (
	emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	// Basic E.164 phone number format validation
	phoneRegex = regexp.MustCompile(`^\+[1-9]\d{1,14}$`)
	// Username and Bubble Name strict format
	nameRegex = regexp.MustCompile(`^[a-z0-9_]+$`)
)

func IsValidEmail(email string) bool {
	return emailRegex.MatchString(email)
}

func IsValidPhone(phone string) bool {
	return phoneRegex.MatchString(phone)
}

func IsValidNameFormat(name string) bool {
	return nameRegex.MatchString(name)
}
