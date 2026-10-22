package service

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"strings"
	"time"
)

type feedService struct {
	repo domain.FeedRepository
}

func NewFeedService(repo domain.FeedRepository) domain.FeedService {
	return &feedService{repo: repo}
}

func (s *feedService) GetFeed(ctx context.Context, userID string, cursorStr string, limit int) ([]*domain.FeedItem, error) {
	if limit <= 0 {
		limit = 20
	} else if limit > 100 {
		limit = 100
	}

	var cursorTime time.Time
	var cursorID string

	if cursorStr != "" {

		parts := strings.Split(cursorStr, ",")
		if len(parts) != 2 || parts[1] == "" {
			return nil, errors.New("invalid cursor format")
		}
		parsed, err := time.Parse(time.RFC3339, parts[0])
		if err != nil {
			return nil, errors.New("invalid cursor format")
		}
		cursorTime = parsed
		cursorID = parts[1]
	}

	return s.repo.GetFeed(ctx, userID, cursorTime, cursorID, limit)
}

func (s *feedService) GetFeedItem(ctx context.Context, userID, postID string) (*domain.FeedItem, error) {
	return s.repo.GetFeedItem(ctx, userID, postID)
}

func (s *feedService) GetExploreFeed(ctx context.Context, userID string, limit int) ([]*domain.FeedItem, error) {
	if limit <= 0 { limit = 20 }
	return s.repo.GetExploreFeed(ctx, userID, limit)
}

func (s *feedService) GetUserFeed(ctx context.Context, requestingUserID, targetUserID string, limit int) ([]*domain.FeedItem, error) {
	if limit <= 0 { limit = 20 }
	return s.repo.GetUserFeed(ctx, requestingUserID, targetUserID, limit)
}
