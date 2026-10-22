package service

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"strings"
)

type replyService struct {
	repo domain.ReplyRepository
}

func NewReplyService(repo domain.ReplyRepository) domain.ReplyService {
	return &replyService{repo: repo}
}

func (s *replyService) CreateReply(ctx context.Context, userID, postID, content string, parentReplyID *string) (*domain.Reply, error) {
	content = strings.TrimSpace(content)
	if content == "" {
		return nil, errors.New("content cannot be empty")
	}

	if parentReplyID != nil {
		trimmedParent := strings.TrimSpace(*parentReplyID)
		if trimmedParent == "" {
			parentReplyID = nil
		} else {
			parentReplyID = &trimmedParent
			parent, err := s.repo.GetByID(ctx, *parentReplyID, "")
			if err != nil {
				return nil, errors.New("parent reply not found")
			}
			if parent.PostID != postID {
				return nil, errors.New("parent reply does not belong to this post")
			}
		}
	}

	reply := &domain.Reply{
		UserID:        userID,
		PostID:        postID,
		Content:       content,
		ParentReplyID: parentReplyID,
	}

	if err := s.repo.Create(ctx, reply); err != nil {
		return nil, err
	}
	return reply, nil
}

func (s *replyService) GetReplyByID(ctx context.Context, id string, requestingUserID string) (*domain.Reply, error) {
	return s.repo.GetByID(ctx, id, requestingUserID)
}

func (s *replyService) GetRepliesByPostID(ctx context.Context, postID string, requestingUserID string) ([]*domain.Reply, error) {
	return s.repo.GetByPostID(ctx, postID, requestingUserID)
}

func (s *replyService) UpdateReply(ctx context.Context, id, userID, content string) (*domain.Reply, error) {
	reply, err := s.repo.GetByID(ctx, id, userID)
	if err != nil {
		return nil, err
	}
	if reply.UserID != userID {
		return nil, errors.New("unauthorized to update this reply")
	}

	content = strings.TrimSpace(content)
	if content == "" {
		return nil, errors.New("content cannot be empty")
	}
	reply.Content = content

	if err := s.repo.Update(ctx, reply); err != nil {
		return nil, err
	}
	return reply, nil
}

func (s *replyService) DeleteReply(ctx context.Context, id, userID string) error {
	reply, err := s.repo.GetByID(ctx, id, userID)
	if err != nil {
		return err
	}
	if reply.UserID != userID {
		return errors.New("unauthorized to delete this reply")
	}
	return s.repo.Delete(ctx, id)
}

func (s *replyService) ReactToReply(ctx context.Context, userID, replyID, emojiType string) (*domain.Reply, error) {
	emojiType = strings.TrimSpace(emojiType)
	if emojiType == "" {
		return nil, errors.New("emoji type cannot be empty")
	}
	if err := s.repo.ReactToReply(ctx, userID, replyID, emojiType); err != nil {
		return nil, err
	}
	return s.repo.GetByID(ctx, replyID, userID)
}

func (s *replyService) RemoveReaction(ctx context.Context, userID, replyID string) (*domain.Reply, error) {
	if err := s.repo.RemoveReaction(ctx, userID, replyID); err != nil {
		return nil, err
	}
	return s.repo.GetByID(ctx, replyID, userID)
}
