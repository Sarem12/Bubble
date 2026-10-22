package http

import (
	"bubble-api/internal/domain"
	"bubble-api/internal/transport/request"
	"bubble-api/internal/transport/response"

	"github.com/gofiber/fiber/v2"
)

type replyHandler struct {
	service domain.ReplyService
}

func NewReplyHandler(service domain.ReplyService) *replyHandler {
	return &replyHandler{service: service}
}

func (h *replyHandler) CreateReply(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	var req request.CreateReplyRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	reply, err := h.service.CreateReply(c.Context(), userID, c.Params("id"), req.Content, req.ParentReplyID)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(response.NewReplyResponse(reply))
}

func (h *replyHandler) GetReplyByID(c *fiber.Ctx) error {
	id := c.Params("id")
	requestingUserID := ""
	if uid, ok := c.Locals("user_id").(string); ok {
		requestingUserID = uid
	}
	reply, err := h.service.GetReplyByID(c.Context(), id, requestingUserID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Reply not found"})
	}
	return c.Status(fiber.StatusOK).JSON(response.NewReplyResponse(reply))
}

func (h *replyHandler) GetRepliesByPostID(c *fiber.Ctx) error {
	postID := c.Params("id")
	requestingUserID := ""
	if uid, ok := c.Locals("user_id").(string); ok {
		requestingUserID = uid
	}
	replies, err := h.service.GetRepliesByPostID(c.Context(), postID, requestingUserID)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(response.NewReplyListResponse(replies))
}

func (h *replyHandler) UpdateReply(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	id := c.Params("id")
	var req request.UpdateReplyRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	reply, err := h.service.UpdateReply(c.Context(), id, userID, req.Content)
	if err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(response.NewReplyResponse(reply))
}

func (h *replyHandler) DeleteReply(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	id := c.Params("id")
	if err := h.service.DeleteReply(c.Context(), id, userID); err != nil {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *replyHandler) ReactToReply(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	id := c.Params("id")
	var req request.ReactToReplyRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	reply, err := h.service.ReactToReply(c.Context(), userID, id, req.EmojiType)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(response.NewReplyResponse(reply))
}

func (h *replyHandler) RemoveReaction(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	id := c.Params("id")
	reply, err := h.service.RemoveReaction(c.Context(), userID, id)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(response.NewReplyResponse(reply))
}
