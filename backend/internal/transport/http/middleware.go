package http

import (
	"bubble-api/internal/domain"
	"strings"

	"github.com/gofiber/fiber/v2"
)

// RequireAuth completely blocks users if they don't have a valid token.
func RequireAuth(tokenService domain.TokenService) fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Missing authorization header"})
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid authorization format"})
		}

		userID, err := tokenService.ValidateToken(parts[1])
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": err.Error()})
		}

		c.Locals("user_id", userID)
		return c.Next()
	}
}

// OptionalAuth lets the user through NO MATTER WHAT.
// If they have a token, it saves the user_id. If they don't, it just stays empty.
func OptionalAuth(tokenService domain.TokenService) fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Next() // No token? Let them through as a Guest!
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) == 2 && parts[0] == "Bearer" {
			userID, err := tokenService.ValidateToken(parts[1])
			if err == nil {
				c.Locals("user_id", userID) // Valid token? Save who they are!
			}
		}

		return c.Next() // Let them through regardless
	}
}
