package utils

import "time"

func CalculateAge(birthday time.Time) int {
	now := time.Now()
	age := now.Year() - birthday.Year()

	if now.Month() < birthday.Month() || (now.Month() == birthday.Month() && now.Day() < birthday.Day()) {
		age--
	}

	if age < 0 {
		return 0
	}
	return age
}

func ParseDate(dateStr string) (time.Time, error) {
	if dateStr == "" {
		return time.Time{}, nil
	}
	t, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return time.Time{}, err
	}
	return t, nil
}
