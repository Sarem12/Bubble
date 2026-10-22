package service

import (
	"bubble-api/internal/domain"
	"context"
)

type activityService struct {
	repo domain.ActivityRepository
}

func NewActivityService(repo domain.ActivityRepository) domain.ActivityService {
	return &activityService{repo: repo}
}

func (s *activityService) GetActivityFeed(ctx context.Context, userID string, limit int, offset int) (*domain.ActivityFeedResponse, error) {
	activities, err := s.repo.GetActivities(ctx, userID, limit, offset)
	if err != nil {
		return nil, err
	}

	friendRequests, err := s.repo.GetPendingFriendRequests(ctx, userID)
	if err != nil {
		return nil, err
	}

	return &domain.ActivityFeedResponse{
		Activities:     activities,
		FriendRequests: friendRequests,
	}, nil
}

func (s *activityService) GetPendingFriendRequests(ctx context.Context, userID string) ([]*domain.FriendRequestItem, error) {
	return s.repo.GetPendingFriendRequests(ctx, userID)
}
