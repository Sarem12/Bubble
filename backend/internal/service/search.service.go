package service

import (
	"bubble-api/internal/domain"
	"context"
	"strings"
)

type searchService struct {
	repo domain.SearchRepository
}

func NewSearchService(repo domain.SearchRepository) domain.SearchService {
	return &searchService{repo: repo}
}

func (s *searchService) SearchAll(ctx context.Context, query string, limit int) (*domain.AllSearchResults, error) {
	users, err := s.SearchUsers(ctx, query, limit)
	if err != nil {
		return nil, err
	}

	bubbles, err := s.SearchBubbles(ctx, query, limit)
	if err != nil {
		return nil, err
	}

	posts, err := s.SearchPosts(ctx, query, limit)
	if err != nil {
		return nil, err
	}

	return &domain.AllSearchResults{
		Users:   users,
		Bubbles: bubbles,
		Posts:   posts,
	}, nil
}

func (s *searchService) SearchUsers(ctx context.Context, query string, limit int) ([]*domain.UserSearchResult, error) {
	query = strings.TrimSpace(query)
	direct := strings.HasPrefix(query, "@")
	if direct {
		query = strings.TrimPrefix(query, "@")
	}
	res, err := s.repo.SearchUsers(ctx, query, direct, limit)
	if err != nil {
		return nil, err
	}
	if res == nil {
		res = []*domain.UserSearchResult{}
	}
	return res, nil
}

func (s *searchService) SearchBubbles(ctx context.Context, query string, limit int) ([]*domain.BubbleSearchResult, error) {
	query = strings.TrimSpace(query)
	direct := strings.HasPrefix(query, "#")
	if direct {
		query = strings.TrimPrefix(query, "#")
	}
	res, err := s.repo.SearchBubbles(ctx, query, direct, limit)
	if err != nil {
		return nil, err
	}
	if res == nil {
		res = []*domain.BubbleSearchResult{}
	}
	return res, nil
}

func (s *searchService) SearchPosts(ctx context.Context, query string, limit int) ([]*domain.PostSearchResult, error) {
	query = strings.TrimSpace(query)
	res, err := s.repo.SearchPosts(ctx, query, limit)
	if err != nil {
		return nil, err
	}
	if res == nil {
		res = []*domain.PostSearchResult{}
	}
	return res, nil
}

func (s *searchService) GetTopPostsForBubble(ctx context.Context, bubbleName string, limit int) ([]*domain.PostSearchResult, error) {
	bubbleName = strings.TrimPrefix(bubbleName, "#")
	res, err := s.repo.GetTopPostsForBubble(ctx, bubbleName, limit)
	if err != nil {
		return nil, err
	}
	if res == nil {
		res = []*domain.PostSearchResult{}
	}
	return res, nil
}
