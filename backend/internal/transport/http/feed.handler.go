package http

import (
	"bubble-api/internal/domain"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type feedHandler struct {
	service domain.FeedService
}

func NewFeedHandler(service domain.FeedService) *feedHandler {
	return &feedHandler{service: service}
}

func (h *feedHandler) GetFeed(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	limitStr := c.Query("limit", "20")
	limit, _ := strconv.Atoi(limitStr)

	cursorStr := c.Query("cursor", "")

	feed, err := h.service.GetFeed(c.Context(), userID, cursorStr, limit)
	if err != nil {
		if strings.Contains(err.Error(), "invalid cursor format") {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}
		return writeServiceError(c, err)
	}

	if feed == nil {
		feed = []*domain.FeedItem{}
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"items": feed,
	})
}

func (h *feedHandler) GetFeedItemByID(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	postID := c.Params("id")

	item, err := h.service.GetFeedItem(c.Context(), userID, postID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "post not found"})
	}

	return c.Status(fiber.StatusOK).JSON(item)
}


func (h *feedHandler) GetExploreFeed(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	limitStr := c.Query("limit", "20")
	limit, _ := strconv.Atoi(limitStr)
	feed, err := h.service.GetExploreFeed(c.Context(), userID, limit)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}
	if feed == nil { feed = make([]*domain.FeedItem, 0) }
	return c.Status(200).JSON(fiber.Map{"items": feed})
}


func (h *feedHandler) GetUserFeed(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	targetUserID := c.Params("id")
	limitStr := c.Query("limit", "20")
	limit, _ := strconv.Atoi(limitStr)
	feed, err := h.service.GetUserFeed(c.Context(), userID, targetUserID, limit)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": err.Error()})
	}
	if feed == nil { feed = make([]*domain.FeedItem, 0) }
	return c.Status(200).JSON(fiber.Map{"items": feed})
}
