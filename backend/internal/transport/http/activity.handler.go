package http

import (
	"bubble-api/internal/domain"
	"strconv"

	"github.com/gofiber/fiber/v2"
)

type activityHandler struct {
	service domain.ActivityService
}

func NewActivityHandler(service domain.ActivityService) *activityHandler {
	return &activityHandler{service: service}
}

func (h *activityHandler) GetActivities(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	limitStr := c.Query("limit", "30")
	limit, _ := strconv.Atoi(limitStr)

	offsetStr := c.Query("offset", "0")
	offset, _ := strconv.Atoi(offsetStr)

	feed, err := h.service.GetActivityFeed(c.Context(), userID, limit, offset)
	if err != nil {
		return writeServiceError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(feed)
}

func (h *activityHandler) GetPendingFriendRequests(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	reqs, err := h.service.GetPendingFriendRequests(c.Context(), userID)
	if err != nil {
		return writeServiceError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"requests": reqs})
}
