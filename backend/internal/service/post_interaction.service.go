package service

import (
	"bubble-api/internal/domain"
	"context"
	"time"
)

type postInteractionService struct {
	repo domain.PostInteractionRepository
}

func NewPostInteractionService(repo domain.PostInteractionRepository) domain.PostInteractionService {
	return &postInteractionService{
		repo: repo,
	}
}

func (s *postInteractionService) ReactToPost(ctx context.Context, userID, postID, emojiType string) (*domain.PostInteraction, error) {
	interaction := &domain.PostInteraction{
		UserID:		userID,
		PostID:		postID,
		EmojiType:	&emojiType,
	}
	return s.repo.UpsertReaction(ctx, interaction)
}

func (s *postInteractionService) RemoveReaction(ctx context.Context, userID, postID string) error {
	return s.repo.RemoveReaction(ctx, userID, postID)
}

func (s *postInteractionService) SavePost(ctx context.Context, userID, postID string, isSaved bool) (*domain.PostInteraction, error) {
	interaction := &domain.PostInteraction{
		UserID:		userID,
		PostID:		postID,
		IsSaved:	isSaved,
	}
	return s.repo.UpsertSave(ctx, interaction)
}

func (s *postInteractionService) ViewPost(ctx context.Context, userID, postID string) (*domain.PostInteraction, error) {
	now := time.Now()
	interaction := &domain.PostInteraction{
		UserID:		userID,
		PostID:		postID,
		LastViewedAt:	&now,
	}
	return s.repo.UpsertView(ctx, interaction)
}

func (s *postInteractionService) GetInteractionsByPost(ctx context.Context, postID string) ([]*domain.PostInteraction, error) {
	return s.repo.GetInteractionsByPost(ctx, postID)
}

func (service *postInteractionService) SharePost(ctx context.Context, userID, postID string) (*domain.PostInteraction, error) {
	interaction, err := service.repo.GetInteraction(ctx, userID, postID)
	if err != nil {
		interaction = &domain.PostInteraction{
			UserID:   userID,
			PostID:   postID,
			IsSaved:  false,
            IsShared: true,
		}
		_, err = service.repo.UpsertShare(ctx, interaction)
		return interaction, err
	}
	interaction.IsShared = true
	_, err = service.repo.UpsertShare(ctx, interaction)
	return interaction, err
}
