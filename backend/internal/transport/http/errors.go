package http

import (
	"errors"
	"log"
	"strings"

	"bubble-api/internal/domain"
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

// writeServiceError translates expected application errors into client errors.
// Services still return ordinary errors today, so the message checks below are
// deliberately centralized here rather than being duplicated in every handler.
func writeServiceError(c *fiber.Ctx, err error) error {
	status := statusForError(err)
	
	// Ensure we NEVER leak raw SQL errors
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		log.Printf("sql error intercepted: %v", err)
		switch pgErr.Code {
		case "23505":
			return c.Status(status).JSON(fiber.Map{"error": getDuplicateErrorMessage(pgErr)})
		case "23503":
			return c.Status(status).JSON(fiber.Map{"error": "Referenced record does not exist."})
		case "23514":
			return c.Status(status).JSON(fiber.Map{"error": "Invalid format or restricted value provided."})
		default:
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Internal server error"})
		}
	}

	if status >= fiber.StatusInternalServerError {
		log.Printf("internal server error: %v", err)
		return c.Status(status).JSON(fiber.Map{"error": "Internal server error"})
	}
	return c.Status(status).JSON(fiber.Map{"error": err.Error()})
}

func statusForError(err error) int {
	if err == nil {
		return fiber.StatusOK
	}
	if errors.Is(err, pgx.ErrNoRows) || errors.Is(err, domain.ErrBubbleNotFound) || errors.Is(err, domain.ErrPersonalBubbleNotFound) {
		return fiber.StatusNotFound
	}

	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		switch pgErr.Code {
		case "23505": // unique_violation
			return fiber.StatusConflict
		case "23503": // foreign_key_violation
			return fiber.StatusNotFound
		case "22001", "22007", "22008", "22P02", "23514": // invalid input/check constraint
			return fiber.StatusBadRequest
		}
	}

	message := strings.ToLower(err.Error())
	switch {
	case strings.Contains(message, "not found"), strings.Contains(message, "no rows"):
		return fiber.StatusNotFound
	case strings.Contains(message, "unauthorized"), strings.Contains(message, "permission"),
		strings.Contains(message, "must join"), strings.Contains(message, "must be logged in"),
		strings.Contains(message, "blocked by"):
		return fiber.StatusForbidden
	case strings.Contains(message, "already exists"), strings.Contains(message, "already friends"),
		strings.Contains(message, "already processed"), strings.Contains(message, "already have"),
		strings.Contains(message, "duplicate key"), strings.Contains(message, "unique_"):
		return fiber.StatusConflict
	case strings.Contains(message, "too many"), strings.Contains(message, "daily limit"),
		strings.Contains(message, "please wait"):
		return fiber.StatusTooManyRequests
	case strings.Contains(message, "invalid"), strings.Contains(message, "cannot"),
		strings.Contains(message, "must "), strings.Contains(message, "empty"),
		strings.Contains(message, "required"), strings.Contains(message, "not allowed"),
		strings.Contains(message, "exceeds"), strings.Contains(message, "incorrect"),
		strings.Contains(message, "no pending"):
		return fiber.StatusBadRequest
	default:
		return fiber.StatusInternalServerError
	}
}

func getDuplicateErrorMessage(pgErr *pgconn.PgError) string {
	if strings.Contains(pgErr.ConstraintName, "username") {
		return "This username is already taken. Please choose another."
	}
	if strings.Contains(pgErr.ConstraintName, "email") {
		return "This email is already registered."
	}
	if strings.Contains(pgErr.ConstraintName, "phone") {
		return "This phone number is already registered."
	}
	return "This record already exists or is duplicated."
}
