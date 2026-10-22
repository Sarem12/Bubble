package service

import (
	"bytes"
	"errors"
	"image/jpeg"
	"mime/multipart"
	"net/http"
	"strings"

	"bubble-api/internal/domain"

	"github.com/disintegration/imaging"
)

type imageProcessor struct{}

func NewImageProcessor() domain.ImageProcessor {
	return &imageProcessor{}
}

func (p *imageProcessor) ProcessProfilePicture(fileHeader *multipart.FileHeader) ([]domain.ImageVariant, error) {
	file, err := fileHeader.Open()
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// RELIABLY DETECT CONTENT TYPE FROM ACTUAL BYTES (Ignores Postman/Frontend headers)
	buffer := make([]byte, 512)
	_, err = file.Read(buffer)
	if err != nil {
		return nil, errors.New("failed to read file headers")
	}
	file.Seek(0, 0) // Reset pointer back to beginning so decoder can read the whole file!

	contentType := http.DetectContentType(buffer)
	if !strings.HasPrefix(contentType, "image/") {
		return nil, errors.New("file is not a valid image. detected type: " + contentType)
	}

	img, err := imaging.Decode(file, imaging.AutoOrientation(true))
	if err != nil {
		return nil, errors.New("failed to decode image format")
	}

	variants := []domain.ImageVariant{}

	sizes := map[string]int{
		"thumbnail": 150,
		"medium":    400,
		"original":  800,
	}

	for name, size := range sizes {
		resized := imaging.Fill(img, size, size, imaging.Center, imaging.Lanczos)

		buf := new(bytes.Buffer)
		err = jpeg.Encode(buf, resized, &jpeg.Options{Quality: 80})
		if err != nil {
			return nil, err
		}

		variants = append(variants, domain.ImageVariant{
			SizeName: name,
			Data:     buf.Bytes(),
			MimeType: "image/jpeg",
		})
	}

	return variants, nil
}
