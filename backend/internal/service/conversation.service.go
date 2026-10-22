package service

import (
	"context"
	"bubble-api/internal/domain"
)

type conversationService struct {
	repo        domain.ConversationRepository
	userService domain.UserService
}

func NewConversationService(repo domain.ConversationRepository, userService domain.UserService) domain.ConversationService {
	return &conversationService{repo: repo, userService: userService}
}

func (s *conversationService) CreateOrGetConversation(ctx context.Context, currentUserID, targetUserID string) (*domain.Conversation, error) {
	return s.repo.CreateOrGet(ctx, currentUserID, targetUserID)
}

func (s *conversationService) GetConversations(ctx context.Context, userID string) ([]*domain.EnrichedConversation, error) {
	convs, err := s.repo.GetConversationsForUser(ctx, userID)
	if err != nil {
		return nil, err
	}
	if convs == nil {
		return []*domain.EnrichedConversation{}, nil
	}

	var enriched []*domain.EnrichedConversation
	for _, c := range convs {
		friendID := c.User1ID
		if friendID == userID {
			friendID = c.User2ID
		}

		friend, err := s.userService.GetUserByID(ctx, friendID)
		if err != nil {
			continue
		}

		enriched = append(enriched, &domain.EnrichedConversation{
			ID:          c.ID,
			FriendID:    friend.ID,
			Username:    friend.Username,
			Avatar:      friend.ProfilePictureURL,
			LastMessage: "No messages yet",
			CreatedAt:   c.CreatedAt,
			UpdatedAt:   c.UpdatedAt,
		})
	}

	if enriched == nil {
		return []*domain.EnrichedConversation{}, nil
	}

	return enriched, nil
}
