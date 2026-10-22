package http

import (
	"bubble-api/internal/domain"
	"bubble-api/internal/transport/request"
	"bubble-api/internal/transport/response"
	"errors"

	"github.com/gofiber/fiber/v2"
)

type postHandler struct {
	service domain.PostService
}

func NewPostHandler(service domain.PostService) *postHandler {
	return &postHandler{service: service}
}

func (h *postHandler) CreatePost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	var req request.CreatePostRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	var domainMedia []domain.PostMediaInput
	for _, m := range req.Media {
		domainMedia = append(domainMedia, domain.PostMediaInput{
			MediaType: m.MediaType,
			URL:       m.URL,
		})
	}
	var bubbleID string
	if req.BubbleID != nil && *req.BubbleID != "" {
		bubbleID = *req.BubbleID
	} else if len(req.BubbleIDs) > 0 {
		bubbleID = req.BubbleIDs[0]
	}
	post, err := h.service.CreatePost(c.Context(), userID, bubbleID, req.Content, domainMedia)
	if err != nil {
		if errors.Is(err, domain.ErrMissingContent) {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
		}
		if errors.Is(err, domain.ErrBubbleNotFound) || errors.Is(err, domain.ErrPersonalBubbleNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": err.Error()})
		}
		if errors.Is(err, domain.ErrMustJoinAll) || errors.Is(err, domain.ErrCannotPostInOtherPerson) {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": err.Error()})
		}
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(response.NewPostResponse(post))
}

func (h *postHandler) GetPostByID(c *fiber.Ctx) error {
	id := c.Params("id")
	userID, _ := c.Locals("user_id").(string)

	post, err := h.service.GetPostByID(c.Context(), id, userID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Post not found"})
	}
	return c.Status(fiber.StatusOK).JSON(response.NewPostResponse(post))
}

func (h *postHandler) UpdatePost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	id := c.Params("id")
	var req request.UpdatePostRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	post, err := h.service.UpdatePost(c.Context(), id, userID, req.Content)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(response.NewPostResponse(post))
}

func (h *postHandler) DeletePost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	id := c.Params("id")
	if err := h.service.DeletePost(c.Context(), id, userID); err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *postHandler) GetMyNotificationSettings(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	settings, err := h.service.GetUserNotificationSettings(c.Context(), userID)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(settings)
}

func (h *postHandler) UpdateNotificationSettings(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	var req request.UpdatePostNotificationRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}
	params := domain.UpdatePostNotificationParams{
		Reactions: req.Reactions,
		Comments:  req.Comments,
		Replies:   req.Replies,
	}
	if err := h.service.UpdatePostNotificationSettings(c.Context(), c.Params("id"), userID, params); err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}
