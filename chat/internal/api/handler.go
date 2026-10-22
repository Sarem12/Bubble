package api

import (
	"strconv"
	"strings"

	"chat/internal/auth"
	"chat/internal/storage"

	"github.com/gofiber/fiber/v2"
)

// AuthMiddleware validates the short-lived access JWT for REST endpoints
func AuthMiddleware(c *fiber.Ctx) error {
	authHeader := c.Get("Authorization")
	if authHeader == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Missing Authorization header"})
	}

	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid Authorization header format"})
	}

	userID, err := auth.ValidateToken(parts[1])
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid or expired token"})
	}

	c.Locals("user_id", userID)
	return c.Next()
}

func GetConversations(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	convs, err := storage.GetConversations(c.Context(), userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to fetch conversations"})
	}

	if convs == nil {
		convs = []storage.Conversation{}
	}

	return c.Status(fiber.StatusOK).JSON(convs)
}

func GetMessages(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	conversationID := c.Params("id")
	
	limitStr := c.Query("limit", "50")
	limit, err := strconv.ParseInt(limitStr, 10, 64)
	if err != nil {
		limit = 50
	}

	_ = userID

	msgs, err := storage.GetMessages(c.Context(), conversationID, limit)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to fetch messages"})
	}

	if msgs == nil {
		msgs = []storage.Message{}
	}

	return c.Status(fiber.StatusOK).JSON(msgs)
}

func GetPresence(c *fiber.Ctx) error {
	userID := c.Params("id")
	if userID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Missing user id"})
	}
	
	isOnline, err := storage.GetUserPresence(c.Context(), userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to check presence"})
	}
	
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"user_id": userID, "online": isOnline})
}

func GetLastMessages(c *fiber.Ctx) error {
	idsParam := c.Query("ids")
	if idsParam == "" {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{})
	}
	
	ids := strings.Split(idsParam, ",")
	lastMessages, err := storage.GetLastMessages(c.Context(), ids)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to fetch last messages"})
	}
	
	return c.Status(fiber.StatusOK).JSON(lastMessages)
}

func DeleteMessage(c *fiber.Ctx) error {
	messageID := c.Params("id")
	conversationID := c.Query("conversation_id")
	if messageID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Missing message id"})
	}

	err := storage.DeleteMessage(c.Context(), messageID, conversationID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to delete message"})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"status": "deleted", "id": messageID})
}

type reactRequest struct {
	Emoji string `json:"emoji"`
}

func ToggleReaction(c *fiber.Ctx) error {
	messageID := c.Params("id")
	userID := c.Locals("user_id").(string)

	var req reactRequest
	if err := c.BodyParser(&req); err != nil || req.Emoji == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid emoji"})
	}

	reactions, err := storage.ToggleReaction(c.Context(), messageID, userID, req.Emoji)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update reaction"})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"reactions": reactions})
}

func DeleteConversation(c *fiber.Ctx) error {
	conversationID := c.Params("id")
	if conversationID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Missing conversation id"})
	}

	err := storage.DeleteConversation(c.Context(), conversationID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to delete conversation"})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"status": "deleted", "conversation_id": conversationID})
}
