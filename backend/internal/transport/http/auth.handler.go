package http

import (
	"bubble-api/internal/domain"
	"bubble-api/internal/transport/request"
	"bubble-api/internal/transport/response"
	"bubble-api/pkg/utils"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type authHandler struct {
	service    domain.AuthService
	otpService domain.OTPService
}

func NewAuthHandler(service domain.AuthService, otpService domain.OTPService) *authHandler {
	return &authHandler{service: service, otpService: otpService}
}

func (h *authHandler) RegisterAnAccount(c *fiber.Ctx) error {
	var req request.RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	if !utils.IsValidNameFormat(req.Username) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Username can only contain lowercase letters, numbers, and underscores"})
	}

	verifToken := c.Get("X-Verification-Token")
	if verifToken == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Missing X-Verification-Token header"})
	}
	verifiedProvider, verifiedIdentifier, purpose, err := h.otpService.ValidateVerificationToken(verifToken)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid or expired verification token"})
	}

	if purpose != "register" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "This token cannot be used for registration"})
	}

	_, sessionToken, err := h.service.RegisterAnAccount(c.Context(), req.Username, req.FirstName, req.LastName, req.Bio, verifiedProvider, verifiedIdentifier, req.Password, req.Birthday, req.DeviceID, req.DeviceName)
	if err != nil {
		errStr := err.Error()
		if strings.Contains(errStr, "invalid birthday format") || strings.Contains(errStr, "password must be") || strings.Contains(errStr, "username must be") || strings.Contains(errStr, "must be at least 7") {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": errStr})
		}
		return writeServiceError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(response.AuthResponse{
		SessionToken: sessionToken,
	})
}

func (h *authHandler) LoginToAccount(c *fiber.Ctx) error {
	var req request.LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	_, sessionToken, err := h.service.LoginToAccount(c.Context(), req.Provider, req.Identifier, req.Password, req.DeviceID, req.DeviceName)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid credentials"})
	}

	return c.Status(fiber.StatusOK).JSON(response.AuthResponse{
		SessionToken: sessionToken,
	})
}

func (h *authHandler) AddProviderToAnAccount(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	var req request.AddProviderRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	verifToken := c.Get("X-Verification-Token")
	if verifToken == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Missing X-Verification-Token header"})
	}
	provider, identifier, purpose, err := h.otpService.ValidateVerificationToken(verifToken)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid or expired verification token."})
	}
	if purpose != "add_provider" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "This token cannot be used for adding a provider"})
	}

	err = h.service.AddProviderToAnAccount(c.Context(), userID, provider, identifier, req.Password)
	if err != nil {
		if strings.Contains(err.Error(), "unique_user_provider") || strings.Contains(err.Error(), "duplicate key") {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "You already have a " + provider + " account linked"})
		}
		return writeServiceError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"message": "created"})
}

func (h *authHandler) LoginWithGoogle(c *fiber.Ctx) error {
	var req request.GoogleLoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	_, sessionToken, err := h.service.LoginWithGoogle(c.Context(), req.IDToken, req.Username, req.DeviceID, req.DeviceName)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(fiber.StatusOK).JSON(response.AuthResponse{
		SessionToken: sessionToken,
	})
}

func (h *authHandler) ChangePassword(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	var req request.ChangePasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	if req.OldPassword == req.NewPassword {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "New password cannot be the same as the old password"})
	}

	err := h.service.ChangePassword(c.Context(), userID, req.OldPassword, req.NewPassword)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *authHandler) GetSessions(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.SendStatus(fiber.StatusUnauthorized)
	}
	sessions, err := h.service.GetUserSessions(c.Context(), userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not load sessions"})
	}
	return c.JSON(fiber.Map{"sessions": sessions})
}

func (h *authHandler) RevokeSession(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.SendStatus(fiber.StatusUnauthorized)
	}
	if err := h.service.RevokeSession(c.Context(), userID, c.Params("id")); err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Session not found"})
	}
	return c.SendStatus(fiber.StatusNoContent)
}

func (h *authHandler) DeleteAccount(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	var req request.DeleteAccountRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	err := h.service.DeleteAccount(c.Context(), userID, req.Password)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "success"})
}

func (h *authHandler) SendOTP(c *fiber.Ctx) error {
	var req request.SendOTPRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	// FORMAT VALIDATION
	if req.Provider == "email" && !utils.IsValidEmail(req.Identifier) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid email format"})
	}
	if req.Provider == "phone" && !utils.IsValidPhone(req.Identifier) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid phone format. Use E.164 (e.g. +1234567890)"})
	}

	// STRICT ENUM VALIDATION
	if req.Purpose != "register" && req.Purpose != "reset_password" && req.Purpose != "add_provider" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "purpose must be exactly 'register', 'reset_password', or 'add_provider'"})
	}

	// PRE-VALIDATION: Check if account exists before sending OTP!
	exists, err := h.service.CheckAccountExists(c.Context(), req.Provider, req.Identifier)
	if err != nil {
		return writeServiceError(c, err)
	}

	if (req.Purpose == "register" || req.Purpose == "add_provider") && exists {
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "This " + req.Provider + " is already in use by an account."})
	}

	if req.Purpose == "reset_password" && !exists {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "No account found with this " + req.Provider + "."})
	}

	err = h.otpService.SendOTP(c.Context(), req.Provider, req.Identifier, req.Purpose)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "Code sent successfully"})
}

func (h *authHandler) VerifyOTP(c *fiber.Ctx) error {
	var req request.VerifyOTPRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}
	token, err := h.otpService.VerifyOTP(c.Context(), req.Identifier, req.Code)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": err.Error()})
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"verification_token": token,
	})
}

func (h *authHandler) ResetPassword(c *fiber.Ctx) error {
	var req request.ResetPasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	verifToken := c.Get("X-Verification-Token")
	if verifToken == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Missing X-Verification-Token header"})
	}
	verifiedProvider, verifiedIdentifier, purpose, err := h.otpService.ValidateVerificationToken(verifToken)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid or expired verification token"})
	}

	if purpose != "reset_password" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "This token cannot be used for password reset"})
	}

	err = h.service.ResetPassword(c.Context(), verifiedProvider, verifiedIdentifier, req.NewPassword)
	if err != nil {
		return writeServiceError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "Password has been successfully reset"})
}

func (h *authHandler) VerifySession(c *fiber.Ctx) error {
	var req request.VerifySessionRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid body"})
	}

	if req.SessionToken == "" || req.DeviceID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "session_token and device_id are required"})
	}

	accessToken, err := h.service.VerifySession(c.Context(), req.SessionToken, req.DeviceID, req.DeviceName)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(fiber.StatusOK).JSON(response.VerifySessionResponse{
		AccessToken: accessToken,
	})
}
