package domain

import (
	"context"
	"io"
	"time"
	"mime/multipart"
)

type PostMedia struct {
	ID		string		`json:"id"`
	PostID		string		`json:"post_id"`
	MediaType	string		`json:"media_type"`
	URL		string		`json:"url"`
	CreatedAt	time.Time	`json:"created_at"`
}

type MediaRepository interface {
	AddMediaToPost(ctx context.Context, media *PostMedia) error
	GetMediaByPostID(ctx context.Context, postID string) ([]*PostMedia, error)
	GetMediaByURL(ctx context.Context, url string) (*PostMedia, error)
	DeleteMedia(ctx context.Context, id string) error
}

type StorageProvider interface {
	Upload(ctx context.Context, filename string, reader io.Reader) (string, error)

	Delete(ctx context.Context, url string) error
}

type MediaService interface {
	UploadMedia(ctx context.Context, filename string, reader io.Reader) (string, error)
	ValidateFile(file *multipart.FileHeader, maxSize int64, allowedPrefixes []string) error
	GeneratePreSignedURL(ctx context.Context, filename string, maxSize int64, allowedPrefixes []string) (string, string, error)
	AuthorizeMediaAccess(ctx context.Context, url string, userID string) (bool, error)
	AddMediaToPost(ctx context.Context, postID, mediaType, url string) (*PostMedia, error)
}


type ImageVariant struct {
	SizeName string // "thumbnail", "medium", "original"
	Data     []byte
	MimeType string // "image/jpeg"
}

// ImageProcessor is responsible for purely resizing and compressing images.
type ImageProcessor interface {
	ProcessProfilePicture(file *multipart.FileHeader) ([]ImageVariant, error)
}

// StorageService is responsible for purely saving files (Local, S3, Cloudinary).
type StorageService interface {
	SaveFile(ctx context.Context, folder, filename string, data []byte) (string, error)
}

// UploadService coordinates the processor and the storage.
type UploadService interface {
	UploadProfilePicture(ctx context.Context, userID string, file *multipart.FileHeader) (map[string]string, error)
}
