package service

import (
	"context"
	"fmt"
	"mime/multipart"
	"time"

	"bubble-api/internal/domain"
)

type mediaUploaderService struct {
	processor domain.ImageProcessor
	storage   domain.StorageService
}

func NewMediaUploaderService(p domain.ImageProcessor, s domain.StorageService) domain.UploadService {
	return &mediaUploaderService{
		processor: p,
		storage:   s,
	}
}

func (s *mediaUploaderService) UploadProfilePicture(ctx context.Context, userID string, fileHeader *multipart.FileHeader) (map[string]string, error) {
	variants, err := s.processor.ProcessProfilePicture(fileHeader)
	if err != nil {
		return nil, err
	}

	baseID := fmt.Sprintf("%s_%d", userID, time.Now().Unix())
	
	urls := make(map[string]string)
	
	urls["base_id"] = baseID

	for _, v := range variants {
		filename := fmt.Sprintf("%s_%s.jpg", baseID, v.SizeName)
		
		url, err := s.storage.SaveFile(ctx, "profile_pictures", filename, v.Data)
		if err != nil {
			return nil, err
		}
		
		urls[v.SizeName] = url
	}

	return urls, nil
}
