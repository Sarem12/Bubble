package http

import (
	"bubble-api/internal/domain"
	"strconv"

	"github.com/gofiber/fiber/v2"
)

func parseLimit(c *fiber.Ctx) int {
	limitStr := c.Query("limit", "20")
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		return 20
	}
	if limit > 100 {
		return 100
	}
	return limit
}

type searchHandler struct {
	service domain.SearchService
}

func NewSearchHandler(service domain.SearchService) *searchHandler {
	return &searchHandler{service: service}
}

func (h *searchHandler) SearchAll(c *fiber.Ctx) error {
	query := c.Query("q")
	results, err := h.service.SearchAll(c.Context(), query, parseLimit(c))
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(results)
}

func (h *searchHandler) SearchUsers(c *fiber.Ctx) error {
	query := c.Query("q")
	results, err := h.service.SearchUsers(c.Context(), query, parseLimit(c))
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(results)
}

func (h *searchHandler) SearchBubbles(c *fiber.Ctx) error {
	query := c.Query("q")
	results, err := h.service.SearchBubbles(c.Context(), query, parseLimit(c))
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(results)
}

func (h *searchHandler) SearchPosts(c *fiber.Ctx) error {
	query := c.Query("q")
	results, err := h.service.SearchPosts(c.Context(), query, parseLimit(c))
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(results)
}

func (h *searchHandler) GetTopPostsForBubble(c *fiber.Ctx) error {
	bubbleName := c.Params("bubbleName")
	results, err := h.service.GetTopPostsForBubble(c.Context(), bubbleName, parseLimit(c))
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(results)
}
