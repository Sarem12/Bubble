package http

import (
	"bubble-api/internal/domain"
	"github.com/gofiber/fiber/v2"
)

type conversationHandler struct {
	service domain.ConversationService
}

func NewConversationHandler(service domain.ConversationService) *conversationHandler {
	return &conversationHandler{service: service}
}

type createConversationRequest struct {
	TargetUserID string `json:"target_user_id"`
}

func (h *conversationHandler) CreateOrGetConversation(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	var req createConversationRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid request body"})
	}
	if req.TargetUserID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "target_user_id is required"})
	}

	conv, err := h.service.CreateOrGetConversation(c.Context(), userID, req.TargetUserID)
	if err != nil {
		return writeServiceError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(conv)
}

func (h *conversationHandler) GetConversations(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	convs, err := h.service.GetConversations(c.Context(), userID)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(convs)
}
