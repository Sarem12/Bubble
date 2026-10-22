package service

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"strings"
	"time"
)

type mediaService struct {
	repo       domain.MediaRepository
	storage    domain.StorageProvider
	postRepo   domain.PostRepository
	bubbleRepo domain.BubbleRepository
}

func NewMediaService(repo domain.MediaRepository, storage domain.StorageProvider, postRepo domain.PostRepository, bubbleRepo domain.BubbleRepository) domain.MediaService {
	return &mediaService{
		repo:       repo,
		storage:    storage,
		postRepo:   postRepo,
		bubbleRepo: bubbleRepo,
	}
}

func (s *mediaService) UploadMedia(ctx context.Context, filename string, reader io.Reader) (string, error) {
	if filename == "" {
		return "", errors.New("filename is empty")
	}
	return s.storage.Upload(ctx, filename, reader)
}

func (s *mediaService) AddMediaToPost(ctx context.Context, postID, mediaType, url string) (*domain.PostMedia, error) {
	mediaType = strings.ToUpper(mediaType)
	if mediaType != "IMAGE" && mediaType != "VIDEO" {
		return nil, errors.New("media_type must be IMAGE or VIDEO")
	}

	media := &domain.PostMedia{
		PostID:    postID,
		MediaType: mediaType,
		URL:       url,
	}

	if err := s.repo.AddMediaToPost(ctx, media); err != nil {
		return nil, err
	}
	return media, nil
}

func (s *mediaService) AuthorizeMediaAccess(ctx context.Context, url string, userID string) (bool, error) {

	media, err := s.repo.GetMediaByURL(ctx, url)
	if err != nil {

		return false, errors.New("media not attached to a post or not found")
	}

	post, err := s.postRepo.GetByID(ctx, media.PostID)
	if err != nil {
		return false, errors.New("post not found")
	}

	var isAuthorized bool
	if post.BubbleID == "" {
		// Personal Post media.
		if post.UserID == userID {
			isAuthorized = true
		}
	} else {
		bubble, err := s.bubbleRepo.GetByID(ctx, post.BubbleID)
		if err == nil {
			if bubble.Type == "PUBLIC" {
				isAuthorized = true
			} else if bubble.Type == "PERSON" {
				if bubble.OwnerID != nil && *bubble.OwnerID == userID {
					isAuthorized = true
				} else if userID != "" {
					members, err := s.bubbleRepo.GetMembers(ctx, bubble.ID)
					if err == nil {
						for _, m := range members {
							if m.UserID == userID {
								isAuthorized = true
								break
							}
						}
					}
				}
			} else if userID != "" {
				members, err := s.bubbleRepo.GetMembers(ctx, bubble.ID)
				if err == nil {
					for _, m := range members {
						if m.UserID == userID {
							isAuthorized = true
							break
						}
					}
				}
			}
		}
	}
	if !isAuthorized {
		return false, errors.New("unauthorized")
	}
	return true, nil
}

func (s *mediaService) ValidateFile(fileHeader *multipart.FileHeader, maxSize int64, allowedPrefixes []string) error {
	if fileHeader.Size > maxSize {
		return errors.New("file exceeds maximum allowed size")
	}

	file, err := fileHeader.Open()
	if err != nil {
		return errors.New("could not open file for validation")
	}
	defer file.Close()

	buffer := make([]byte, 512)
	_, _ = file.Read(buffer)
	file.Seek(0, 0) // reset

	contentType := http.DetectContentType(buffer)
	isValidType := false
	for _, prefix := range allowedPrefixes {
		if strings.HasPrefix(contentType, prefix) {
			isValidType = true
			break
		}
	}

	if !isValidType {
		return errors.New("file type not allowed. detected: " + contentType)
	}

	return nil
}

func (s *mediaService) GeneratePreSignedURL(ctx context.Context, filename string, maxSize int64, allowedPrefixes []string) (string, string, error) {
	// Security Check: Ensure the filename has a safe extension based on allowedPrefixes
	filenameLower := strings.ToLower(filename)
	isValidExt := false
	if len(allowedPrefixes) > 0 {
		for _, prefix := range allowedPrefixes {
			if prefix == "image/" && (strings.HasSuffix(filenameLower, ".jpg") || strings.HasSuffix(filenameLower, ".png") || strings.HasSuffix(filenameLower, ".jpeg")) {
				isValidExt = true
				break
			}
			if prefix == "video/" && (strings.HasSuffix(filenameLower, ".mp4") || strings.HasSuffix(filenameLower, ".mov")) {
				isValidExt = true
				break
			}
		}
		if !isValidExt {
			return "", "", errors.New("invalid file extension for allowed media types")
		}
	}

	// 3. Generate Unique Filename
	uniqueFilename := fmt.Sprintf("%d_%s", time.Now().UnixNano(), filename)

	// 4. MOCK AWS S3 TICKET GENERATION
	// In the future, you will use github.com/aws/aws-sdk-go-v2/service/s3 here to generate a real ticket.
	mockAWSUploadURL := fmt.Sprintf("https://bubble-production-bucket.s3.amazonaws.com/uploads/%s?AWSAccessKeyId=MOCK&Expires=300&Signature=MOCK&MaxSize=%d", uniqueFilename, maxSize)

	// 5. The final public URL that the frontend will save to the database AFTER successfully uploading
	finalPublicURL := "https://bubble-production-bucket.s3.amazonaws.com/uploads/" + uniqueFilename

	return mockAWSUploadURL, finalPublicURL, nil
}
