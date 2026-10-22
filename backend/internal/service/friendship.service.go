package service

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"strings"
)

type friendshipService struct {
	repo          domain.FriendshipRepository
	bubbleService domain.BubbleService
}

func NewFriendshipService(repo domain.FriendshipRepository, bubbleService domain.BubbleService) domain.FriendshipService {
	return &friendshipService{repo: repo, bubbleService: bubbleService}
}

func (s *friendshipService) SendRequest(ctx context.Context, sourceID, targetID string) error {
	if sourceID == targetID {
		return errors.New("cannot send friend request to yourself")
	}

	existingReverse, _ := s.repo.Get(ctx, targetID, sourceID)
	if existingReverse != nil && existingReverse.State == "blocked" {
		return errors.New("you are blocked by this user")
	}
	if existingReverse != nil && existingReverse.State == "friend" {
		return errors.New("already friends")
	}

	existingForward, _ := s.repo.Get(ctx, sourceID, targetID)
	if existingForward != nil {
		return errors.New("request already exists or already friends")
	}

	f1 := &domain.Friendship{
		SourceUserID:           sourceID,
		TargetUserID:           targetID,
		State:                  "request_sent",
		IsBestfriend:           false,
		IgnoreInFeed:           false,
		NotificationState:      "AUTOMATIC",
		ExceptionBubbles:       []string{},
		InviteState:            "AUTOMATIC",
		InviteExceptionBubbles: []string{},
	}

	f2 := &domain.Friendship{
		SourceUserID:           targetID,
		TargetUserID:           sourceID,
		State:                  "request_received",
		IsBestfriend:           false,
		IgnoreInFeed:           false,
		NotificationState:      "AUTOMATIC",
		ExceptionBubbles:       []string{},
		InviteState:            "AUTOMATIC",
		InviteExceptionBubbles: []string{},
	}

	return s.repo.UpsertMutual(ctx, f1, f2)
}

func (s *friendshipService) AcceptRequest(ctx context.Context, targetID, sourceID string) error {
	f1, err := s.repo.Get(ctx, targetID, sourceID)
	if err != nil || f1.State != "request_received" {
		return errors.New("no pending request found")
	}

	f2, err := s.repo.Get(ctx, sourceID, targetID)
	if err != nil || f2.State != "request_sent" {
		return errors.New("no pending request found on sender side")
	}

	f1.State = "friend"
	f2.State = "friend"

	err = s.repo.UpsertMutual(ctx, f1, f2)
	if err != nil {
		return err
	}

	// Auto-join each other's personal bubbles
	targetBubble, errT := s.bubbleService.GetPersonBubbleByOwnerID(ctx, targetID)
	sourceBubble, errS := s.bubbleService.GetPersonBubbleByOwnerID(ctx, sourceID)

	var joinErr error
	var joinedTarget, joinedSource bool

	if errT == nil {
		if err := s.bubbleService.JoinPersonBubble(ctx, sourceID, targetBubble.ID); err != nil {
			joinErr = err
		} else {
			joinedTarget = true
		}
	}
	if errS == nil {
		if err := s.bubbleService.JoinPersonBubble(ctx, targetID, sourceBubble.ID); err != nil {
			joinErr = err
		} else {
			joinedSource = true
		}
	}

	if joinErr != nil {
		if joinedTarget {
			_ = s.bubbleService.LeaveBubble(ctx, sourceID, targetBubble.ID)
		}
		if joinedSource {
			_ = s.bubbleService.LeaveBubble(ctx, targetID, sourceBubble.ID)
		}

		if delErr := s.repo.DeleteMutual(ctx, targetID, sourceID); delErr != nil {
			return errors.New("join failed and rollback failed")
		}
		return joinErr
	}

	return nil
}

func (s *friendshipService) DeclineRequest(ctx context.Context, targetID, sourceID string) error {
	return s.repo.DeleteMutual(ctx, targetID, sourceID)
}

func (s *friendshipService) RemoveFriend(ctx context.Context, sourceID, targetID string) error {
	if sourceID == targetID {
		return errors.New("invalid target user")
	}
	err := s.repo.DeleteMutual(ctx, sourceID, targetID)
	if err != nil {
		return err
	}

	targetBubble, errT := s.bubbleService.GetPersonBubbleByOwnerID(ctx, targetID)
	sourceBubble, errS := s.bubbleService.GetPersonBubbleByOwnerID(ctx, sourceID)

	var leaveErr error
	if errT == nil {
		if err := s.bubbleService.LeaveBubble(ctx, sourceID, targetBubble.ID); err != nil {
			leaveErr = err
		}
	} else if !strings.Contains(errT.Error(), "no rows") {
		leaveErr = errT
	}

	if errS == nil {
		if err := s.bubbleService.LeaveBubble(ctx, targetID, sourceBubble.ID); err != nil {
			leaveErr = err
		}
	} else if !strings.Contains(errS.Error(), "no rows") {
		leaveErr = errS
	}

	return leaveErr
}

func (s *friendshipService) BlockUser(ctx context.Context, sourceID, targetID string) error {
	if sourceID == targetID {
		return errors.New("you cannot block yourself")
	}
	f := &domain.Friendship{
		SourceUserID:           sourceID,
		TargetUserID:           targetID,
		State:                  "blocked",
		NotificationState:      "AUTOMATIC",
		ExceptionBubbles:       []string{},
		InviteState:            "AUTOMATIC",
		InviteExceptionBubbles: []string{},
	}
	return s.repo.BlockUserAtomic(ctx, f, sourceID, targetID)
}

func (s *friendshipService) UnblockUser(ctx context.Context, sourceID, targetID string) error {
	if sourceID == targetID {
		return errors.New("you cannot unblock yourself")
	}
	return s.repo.Delete(ctx, sourceID, targetID)
}

func (s *friendshipService) UpdateSettings(ctx context.Context, sourceID, targetID string, isBestfriend *bool, ignoreInFeed *bool, notifState *string, exceptions []string, inviteState *string, inviteExceptions []string) (*domain.Friendship, error) {
	f, err := s.repo.Get(ctx, sourceID, targetID)
	if err != nil {
		return nil, errors.New("friendship not found")
	}

	if isBestfriend != nil {
		f.IsBestfriend = *isBestfriend
	}
	if ignoreInFeed != nil {
		f.IgnoreInFeed = *ignoreInFeed
	}
	if notifState != nil {
		f.NotificationState = *notifState
	}
	if exceptions != nil {
		f.ExceptionBubbles = exceptions
	}
	if inviteState != nil {
		f.InviteState = *inviteState
	}
	if inviteExceptions != nil {
		f.InviteExceptionBubbles = inviteExceptions
	}

	return s.repo.Upsert(ctx, f)
}

func (s *friendshipService) GetRequests(ctx context.Context, userID string) ([]*domain.Friendship, error) {
	return s.repo.GetByState(ctx, userID, "request_received")
}

func (s *friendshipService) GetFriends(ctx context.Context, userID string) ([]*domain.Friendship, error) {
	return s.repo.GetByState(ctx, userID, "friend")
}

func (s *friendshipService) GetBlocked(ctx context.Context, userID string) ([]*domain.Friendship, error) {
	return s.repo.GetByState(ctx, userID, "blocked")
}
