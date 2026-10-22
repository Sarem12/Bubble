package http

import (
	"bubble-api/internal/domain"
	"bubble-api/internal/transport/request"
	"bubble-api/internal/transport/response"
	"bubble-api/pkg/utils"
	"time"

	"github.com/gofiber/fiber/v2"
)

type userHandler struct {
	service       domain.UserService
	uploadService domain.UploadService
	mediaService  domain.MediaService
}

func NewUserHandler(service domain.UserService, uploadService domain.UploadService, mediaService domain.MediaService) *userHandler {
	return &userHandler{service: service, uploadService: uploadService, mediaService: mediaService}
}

// NewPersonHandler is an alias constructor for backwards compatibility.
func NewPersonHandler(service domain.UserService, uploadService domain.UploadService, mediaService domain.MediaService) *userHandler {
	return NewUserHandler(service, uploadService, mediaService)
}

func (h *userHandler) CreateUser(c *fiber.Ctx) error {
	var req request.CreateUserRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	birthday, err := utils.ParseDate(req.Birthday)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid birthday format, use YYYY-MM-DD"})
	}

	user, err := h.service.CreateUser(c.Context(), req.Username, req.FirstName, req.LastName, req.Bio, req.ProfilePictureURL, birthday)
	if err != nil {
		return writeServiceError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(response.NewUserResponse(user))
}

func (h *userHandler) CreatePerson(c *fiber.Ctx) error {
	return h.CreateUser(c)
}

func (h *userHandler) GetMyProfile(c *fiber.Ctx) error {
	id, ok := c.Locals("user_id").(string)
	if !ok || id == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}
	user, err := h.service.GetUserByID(c.Context(), id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
	}
	return c.Status(fiber.StatusOK).JSON(response.NewUserResponse(user))
}

func (h *userHandler) GetUserByID(c *fiber.Ctx) error {
	id := c.Params("id")
	if id == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "ID is required"})
	}
	user, err := h.service.GetUserByID(c.Context(), id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
	}
	return c.Status(fiber.StatusOK).JSON(response.NewUserResponse(user))
}

func (h *userHandler) GetPersonByID(c *fiber.Ctx) error {
	return h.GetUserByID(c)
}

func (h *userHandler) UpdateUser(c *fiber.Ctx) error {
	id, ok := c.Locals("user_id").(string)
	if !ok || id == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}
	var req request.UpdateUserRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	birthday, err := utils.ParseDate(req.Birthday)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid birthday format, use YYYY-MM-DD"})
	}

	user, err := h.service.UpdateUser(c.Context(), id, req.Username, req.FirstName, req.LastName, req.Bio, req.ProfilePictureURL, req.Type, birthday)
	if err != nil {
		return writeServiceError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(response.NewUserResponse(user))
}

func (h *userHandler) UpdatePerson(c *fiber.Ctx) error {
	return h.UpdateUser(c)
}

func (h *userHandler) GetSettings(c *fiber.Ctx) error {
	id, ok := c.Locals("user_id").(string)
	if !ok || id == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}
	settings, err := h.service.GetSettings(c.Context(), id)
	if err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(settings)
}

func (h *userHandler) UpdateSettings(c *fiber.Ctx) error {
	id, ok := c.Locals("user_id").(string)
	if !ok || id == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}
	var req request.UpdateUserSettingsRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	settings, err := h.service.UpdateSettings(c.Context(), id, domain.UpdateSettingsParams{
		NotificationState:           req.NotificationState,
		InvitationState:             req.InvitationState,
		GlobalReactionNotifications: req.GlobalReactionNotifications,
		GlobalCommentNotifications:  req.GlobalCommentNotifications,
		GlobalReplyNotifications:    req.GlobalReplyNotifications,
		MessageNotifications:        req.MessageNotifications,
		AllowNewChats:               req.AllowNewChats,
		TopReactions:                req.TopReactions,
	})
	if err != nil {
		return writeServiceError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(settings)
}

func (h *userHandler) DeleteUser(c *fiber.Ctx) error {
	id, ok := c.Locals("user_id").(string)
	if !ok || id == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}
	if err := h.service.DeleteUser(c.Context(), id); err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *userHandler) DeletePerson(c *fiber.Ctx) error {
	return h.DeleteUser(c)
}

func (h *userHandler) GetUserByUsername(c *fiber.Ctx) error {
	username := c.Params("username")
	user, err := h.service.GetUserByUsername(c.Context(), username)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
	}
	return c.Status(fiber.StatusOK).JSON(response.NewUserResponse(user))
}

func (h *userHandler) GetPersonByUsername(c *fiber.Ctx) error {
	return h.GetUserByUsername(c)
}

func (h *userHandler) UploadProfilePicture(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	fileHeader, err := c.FormFile("profile_picture")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "No image file provided"})
	}

	if fileHeader.Size > 5*1024*1024 {
		return c.Status(fiber.StatusRequestEntityTooLarge).JSON(fiber.Map{"error": "File is too large. Maximum size is 5 MB."})
	}

	urls, err := h.uploadService.UploadProfilePicture(c.Context(), userID, fileHeader)
	if err != nil {
		return writeServiceError(c, err)
	}

	baseID := urls["base_id"]

	profilePictureURL := urls["medium"]
	if profilePictureURL == "" {
		profilePictureURL = urls["original"]
	}
	thumbnailURL := urls["thumbnail"]

	_ = h.service.UpdateProfilePicture(c.Context(), userID, profilePictureURL)

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message":             "Profile picture uploaded successfully",
		"base_id":             baseID,
		"profile_picture_url": profilePictureURL,
		"thumbnail_url":       thumbnailURL,
		"url":                 profilePictureURL,
		"preview_urls":        urls,
	})
}

func (h *userHandler) UpdateLastActive(c *fiber.Ctx) error {
	id := c.Params("id")
	if id == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "ID is required"})
	}

	err := h.service.UpdateLastActive(c.Context(), id, time.Now())
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to update last active"})
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"status": "success"})
}
