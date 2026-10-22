package http

import (
	"bubble-api/internal/domain"
	"bubble-api/internal/transport/request"
	"bubble-api/internal/transport/response"

	"github.com/gofiber/fiber/v2"
)

type friendshipHandler struct {
	service     domain.FriendshipService
	userService domain.UserService
}

func NewFriendshipHandler(service domain.FriendshipService, userService domain.UserService) *friendshipHandler {
	return &friendshipHandler{service: service, userService: userService}
}

func (h *friendshipHandler) SendRequest(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}
	var req request.SendFriendRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	if err := h.service.SendRequest(c.Context(), userID, req.TargetUserID); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"message": "created"})
}

func (h *friendshipHandler) AcceptRequest(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	targetID := c.Params("id")

	if err := h.service.AcceptRequest(c.Context(), userID, targetID); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *friendshipHandler) DeclineRequest(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	targetID := c.Params("id")

	if err := h.service.DeclineRequest(c.Context(), userID, targetID); err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *friendshipHandler) RemoveFriend(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	targetID := c.Params("id")

	if err := h.service.RemoveFriend(c.Context(), userID, targetID); err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *friendshipHandler) BlockUser(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	targetID := c.Params("id")

	if err := h.service.BlockUser(c.Context(), userID, targetID); err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *friendshipHandler) UnblockUser(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	if err := h.service.UnblockUser(c.Context(), userID, c.Params("id")); err != nil {
		return writeServiceError(c, err)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *friendshipHandler) UpdateSettings(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	targetID := c.Params("id")
	var req request.UpdateFriendshipSettingsRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	fs, err := h.service.UpdateSettings(c.Context(), userID, targetID, req.IsBestfriend, req.IgnoreInFeed, req.NotificationState, req.ExceptionBubbles, req.InviteState, req.InviteExceptionBubbles)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(response.NewFriendshipResponse(fs))
}

func (h *friendshipHandler) GetRequests(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	reqs, err := h.service.GetRequests(c.Context(), userID)
	if err != nil {
		return writeServiceError(c, err)
	}

	var enrichedRequests []fiber.Map
	for _, req := range reqs {
		senderID := req.TargetUserID
		person, err := h.userService.GetUserByID(c.Context(), senderID)
		username := ""
		avatar := ""
		firstName := ""
		lastName := ""
		if err == nil && person != nil {
			username = person.Username
			avatar = person.ProfilePictureURL
			firstName = person.FirstName
			lastName = person.LastName
		}
		enrichedRequests = append(enrichedRequests, fiber.Map{
			"id":                  senderID,
			"source_user_id":      req.SourceUserID,
			"target_user_id":      req.TargetUserID,
			"user_id":             senderID,
			"sender_id":           senderID,
			"username":            username,
			"first_name":          firstName,
			"last_name":           lastName,
			"profile_picture_url": avatar,
			"avatar":              avatar,
			"state":               req.State,
			"created_at":          req.CreatedAt,
		})
	}

	if enrichedRequests == nil {
		enrichedRequests = []fiber.Map{}
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"requests": enrichedRequests})
}

func (h *friendshipHandler) GetFriends(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	friends, err := h.service.GetFriends(c.Context(), userID)
	if err != nil {
		return writeServiceError(c, err)
	}

	// Enrich with person data
	var enrichedFriends []fiber.Map
	for _, f := range friends {
		// TargetUserID is the friend's ID if the state is friend.
		// Wait, if GetFriends returns friendships where source_user_id = userID, then target_user_id is the friend!
		friendID := f.TargetUserID
		person, err := h.userService.GetUserByID(c.Context(), friendID)

		username := ""
		avatar := ""
		firstName := ""
		lastName := ""
		if err == nil && person != nil {
			username = person.Username
			avatar = person.ProfilePictureURL
			firstName = person.FirstName
			lastName = person.LastName
		}

		enrichedFriends = append(enrichedFriends, fiber.Map{
			"source_user_id":           f.SourceUserID,
			"target_user_id":           f.TargetUserID,
			"friend_id":                friendID,
			"friend_username":          username,
			"friend_first_name":        firstName,
			"friend_last_name":         lastName,
			"friend_avatar":            avatar,
			"state":                    f.State,
			"is_bestfriend":            f.IsBestfriend,
			"ignore_in_feed":           f.IgnoreInFeed,
			"notification_state":       f.NotificationState,
			"exception_bubbles":        f.ExceptionBubbles,
			"invite_state":             f.InviteState,
			"invite_exception_bubbles": f.InviteExceptionBubbles,
		})
	}

	if enrichedFriends == nil {
		enrichedFriends = []fiber.Map{}
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"friends": enrichedFriends})
}

func (h *friendshipHandler) GetBlocked(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)
	blocked, err := h.service.GetBlocked(c.Context(), userID)
	if err != nil {
		return writeServiceError(c, err)
	}
	result := make([]fiber.Map, 0, len(blocked))
	for _, friendship := range blocked {
		person, _ := h.userService.GetUserByID(c.Context(), friendship.TargetUserID)
		entry := fiber.Map{"id": friendship.TargetUserID}
		if person != nil {
			entry["username"] = person.Username
			entry["first_name"] = person.FirstName
			entry["last_name"] = person.LastName
			entry["profile_picture_url"] = person.ProfilePictureURL
		}
		result = append(result, entry)
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"blocked_users": result})
}
