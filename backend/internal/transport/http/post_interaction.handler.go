package http

import (
	"bubble-api/internal/domain"
	"bubble-api/internal/transport/request"
	"bubble-api/internal/transport/response"

	"github.com/gofiber/fiber/v2"
)

type postInteractionHandler struct {
	service domain.PostInteractionService
}

func NewPostInteractionHandler(service domain.PostInteractionService) *postInteractionHandler {
	return &postInteractionHandler{service: service}
}

func (h *postInteractionHandler) ReactToPost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	postID := c.Params("id")
	var req request.ReactToPostRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}


	interaction, err := h.service.ReactToPost(c.Context(), userID, postID, req.EmojiType)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(response.NewPostInteractionResponse(interaction))
}

func (h *postInteractionHandler) RemoveReaction(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	postID := c.Params("id")

	if err := h.service.RemoveReaction(c.Context(), userID, postID); err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *postInteractionHandler) SavePost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	postID := c.Params("id")
	var req request.SavePostRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	interaction, err := h.service.SavePost(c.Context(), userID, postID, req.IsSaved)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(response.NewPostInteractionResponse(interaction))
}

func (h *postInteractionHandler) ViewPost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	postID := c.Params("id")

	interaction, err := h.service.ViewPost(c.Context(), userID, postID)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(response.NewPostInteractionResponse(interaction))
}

func (h *postInteractionHandler) GetInteractionsByPost(c *fiber.Ctx) error {
	postID := c.Params("id")

	interactions, err := h.service.GetInteractionsByPost(c.Context(), postID)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(response.NewPostInteractionListResponse(interactions))
}

func (h *postInteractionHandler) SharePost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	postID := c.Params("id")
	_, err := h.service.SharePost(c.Context(), userID, postID)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}
