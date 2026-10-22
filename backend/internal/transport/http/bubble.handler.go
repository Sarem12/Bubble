package http

import (
	"bubble-api/internal/domain"
	"bubble-api/internal/transport/request"
	"bubble-api/internal/transport/response"
	"bubble-api/pkg/utils"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type bubbleHandler struct {
	service domain.BubbleService
}

func (h *bubbleHandler) UpdateNotifications(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}
	var req struct {
		Enabled bool `json:"notifications_enabled"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}
	if err := h.service.UpdateMemberNotifications(c.Context(), userID, c.Params("id"), req.Enabled); err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"notifications_enabled": req.Enabled})
}

func NewBubbleHandler(service domain.BubbleService) *bubbleHandler {
	return &bubbleHandler{service: service}
}

func (h *bubbleHandler) CreateBubble(c *fiber.Ctx) error {
	var req request.CreateBubbleRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	if !utils.IsValidNameFormat(req.Name) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Bubble name can only contain lowercase letters, numbers, and underscores"})
	}

	userID := c.Locals("user_id").(string)
	bubble, err := h.service.CreateBubble(c.Context(), req.Name, req.Description, req.Type, userID, req.MemberKey)
	if err != nil {
		if strings.Contains(err.Error(), "must be PUBLIC") || strings.Contains(err.Error(), "must be at least") {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}
		return writeServiceError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(response.NewBubbleResponse(bubble))
}

func (h *bubbleHandler) GetBubbleByName(c *fiber.Ctx) error {
	name := c.Params("name")
	bubble, err := h.service.GetBubbleByName(c.Context(), name)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Bubble not found"})
	}
	return c.Status(fiber.StatusOK).JSON(response.NewBubbleResponse(bubble))
}

func (h *bubbleHandler) GetBubbles(c *fiber.Ctx) error {
	nameFilter := c.Query("name", "")
	sortBy := c.Query("sort", "popular") // Default to big communities

	limit := 100
	if c.Query("limit") != "" {
		limit = c.QueryInt("limit", 100)
		if limit > 100 {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Limit cannot exceed 100 to prevent server abuse"})
		}
	}

	bubbles, err := h.service.GetBubbles(c.Context(), nameFilter, sortBy, limit)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(response.NewBubbleListResponse(bubbles))
}

func (h *bubbleHandler) DeleteBubble(c *fiber.Ctx) error {
	id := c.Params("id")
	if err := h.service.DeleteBubble(c.Context(), id); err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *bubbleHandler) JoinBubble(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	bubbleID := c.Params("id")

	var req request.JoinBubbleRequest
	_ = c.BodyParser(&req)

	if err := h.service.JoinBubble(c.Context(), userID, bubbleID, req.MemberKey); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *bubbleHandler) LeaveBubble(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	bubbleID := c.Params("id")

	if err := h.service.LeaveBubble(c.Context(), userID, bubbleID); err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *bubbleHandler) GetMembers(c *fiber.Ctx) error {
	bubbleID := c.Params("id")
	members, err := h.service.GetBubbleMembers(c.Context(), bubbleID)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"members": members})
}

func (h *bubbleHandler) InviteToBubble(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	bubbleID := c.Params("id")

	var req request.InviteUserRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	if err := h.service.InviteToBubble(c.Context(), userID, req.TargetUserID, bubbleID); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"message": "created"})
}

func (h *bubbleHandler) AcceptInvitation(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	inviteID := c.Params("id")

	if err := h.service.AcceptInvitation(c.Context(), userID, inviteID); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *bubbleHandler) DeclineInvitation(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	inviteID := c.Params("id")

	if err := h.service.DeclineInvitation(c.Context(), userID, inviteID); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *bubbleHandler) GetUserBubbles(c *fiber.Ctx) error {
	targetUserID := c.Params("id")
	authUserID, _ := c.Locals("user_id").(string)
	isSelf := authUserID != "" && authUserID == targetUserID

	bubbles, err := h.service.GetUserBubbles(c.Context(), targetUserID, isSelf)
	if err != nil {
		return writeServiceError(c, err)
	}
	if bubbles == nil {
		bubbles = []*domain.Bubble{}
	}
	return c.Status(fiber.StatusOK).JSON(bubbles)
}
