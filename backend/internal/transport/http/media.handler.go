package http

import (
	"bubble-api/internal/domain"
	"bytes"
	"fmt"
	"image/jpeg"
	"strings"
	"time"

	"github.com/disintegration/imaging"
	"github.com/gofiber/fiber/v2"
)

type mediaHandler struct {
	service domain.MediaService
}

func NewMediaHandler(service domain.MediaService) *mediaHandler {
	return &mediaHandler{service: service}
}

func (h *mediaHandler) UploadMedia(c *fiber.Ctx) error {

	file, err := c.FormFile("file")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "file upload failed"})
	}

	// UNIFIED VALIDATION SERVICE
	if err := h.service.ValidateFile(file, 50*1024*1024, []string{"image/", "video/"}); err != nil {
		if strings.Contains(err.Error(), "size") {
			return c.Status(fiber.StatusRequestEntityTooLarge).JSON(fiber.Map{"error": "Media is too large. Maximum size is 50 MB."})
		}
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": err.Error()})
	}

	fileData, err := file.Open()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "could not open file"})
	}
	defer fileData.Close()

	// Make the filename universally unique
	uniqueFilename := fmt.Sprintf("%d_%s", time.Now().UnixNano(), file.Filename)

	// Attempt thumbnail generation if media is an image
	var thumbURL string
	contentType := file.Header.Get("Content-Type")
	filenameLower := strings.ToLower(file.Filename)
	isImage := strings.HasPrefix(contentType, "image/") ||
		strings.HasSuffix(filenameLower, ".jpg") ||
		strings.HasSuffix(filenameLower, ".jpeg") ||
		strings.HasSuffix(filenameLower, ".png") ||
		strings.HasSuffix(filenameLower, ".webp")

	if isImage {
		if img, err := imaging.Decode(fileData, imaging.AutoOrientation(true)); err == nil {
			thumb := imaging.Fit(img, 400, 400, imaging.Lanczos)
			thumbBuf := new(bytes.Buffer)
			if err := jpeg.Encode(thumbBuf, thumb, &jpeg.Options{Quality: 82}); err == nil {
				thumbFilename := fmt.Sprintf("thumb_%d_%s.jpg", time.Now().UnixNano(), file.Filename)
				if tURL, err := h.service.UploadMedia(c.Context(), thumbFilename, thumbBuf); err == nil {
					thumbURL = tURL
				}
			}
		}
		// Reset fileData seeker back to beginning for original upload
		_, _ = fileData.Seek(0, 0)
	}

	url, err := h.service.UploadMedia(c.Context(), uniqueFilename, fileData)
	if err != nil {
		return writeServiceError(c, err)
	}

	res := fiber.Map{"url": url}
	if thumbURL != "" {
		res["thumbnail_url"] = thumbURL
	}

	return c.Status(fiber.StatusOK).JSON(res)
}

func (h *mediaHandler) ServeMedia(c *fiber.Ctx) error {
	filename := c.Params("filename")
	userID, ok := c.Locals("user_id").(string)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "unauthorized"})
	}

	allowed, err := h.service.AuthorizeMediaAccess(c.Context(), filename, userID)
	if err != nil || !allowed {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "access denied"})
	}

	return c.SendFile("./uploads/" + filename)
}
