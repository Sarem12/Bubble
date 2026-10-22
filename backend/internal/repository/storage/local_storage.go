package storage

import (
	"bubble-api/internal/domain"
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

type localStorage struct {
	baseDir	string
	baseURL	string
}

func NewLocalStorageProvider(baseDir, baseURL string) domain.StorageProvider {
	return &localStorage{
		baseDir:	baseDir,
		baseURL:	baseURL,
	}
}

func (s *localStorage) Upload(ctx context.Context, filename string, reader io.Reader) (string, error) {

	ext := filepath.Ext(filename)
	out, err := os.CreateTemp(s.baseDir, "upload_*"+ext)
	if err != nil {
		return "", err
	}
	uniqueFilename := filepath.Base(out.Name())
	defer out.Close()

	_, err = io.Copy(out, reader)
	if err != nil {
		return "", err
	}

	publicURL := fmt.Sprintf("%s/%s", s.baseURL, uniqueFilename)
	return publicURL, nil
}

func (s *localStorage) Delete(ctx context.Context, url string) error {

	filename := filepath.Base(url)
	filePath := filepath.Join(s.baseDir, filename)
	return os.Remove(filePath)
}

func (s *localStorage) SaveFile(ctx context.Context, folder, filename string, data []byte) (string, error) {
	fullDir := filepath.Join(s.baseDir, folder)
	err := os.MkdirAll(fullDir, os.ModePerm)
	if err != nil {
		return "", err
	}

	fullPath := filepath.Join(fullDir, filename)
	err = os.WriteFile(fullPath, data, 0644)
	if err != nil {
		return "", err
	}

	publicURL := fmt.Sprintf("%s/%s/%s", s.baseURL, folder, filename)
	return publicURL, nil
}

func NewLocalStorage(basePath, baseURL string) domain.StorageService {
	os.MkdirAll(basePath, os.ModePerm)
	return &localStorage{
		baseDir: basePath,
		baseURL: baseURL,
	}
}
