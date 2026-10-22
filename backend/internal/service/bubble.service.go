package service

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"strings"
)

type bubbleService struct {
	repo  domain.BubbleRepository
	fRepo domain.FriendshipRepository
}

func NewBubbleService(repo domain.BubbleRepository, fRepo domain.FriendshipRepository) domain.BubbleService {
	return &bubbleService{repo: repo, fRepo: fRepo}
}

func (s *bubbleService) CreateBubble(ctx context.Context, name string, description string, bubbleType string, ownerID string, memberKey string) (*domain.Bubble, error) {
	name = strings.TrimSpace(name)
	if len(name) < 3 {
		return nil, errors.New("bubble name must be at least 3 characters")
	}

	bubbleType = strings.ToUpper(strings.TrimSpace(bubbleType))
	if bubbleType != "PUBLIC" && bubbleType != "PRIVATE" {
		return nil, errors.New("bubble type must be PUBLIC or PRIVATE")
	}

	var mk *string
	if bubbleType == "PRIVATE" && memberKey != "" {
		mk = &memberKey
	}

	bubble := &domain.Bubble{
		Name:        name,
		Description: strings.TrimSpace(description),
		Type:        bubbleType,
		OwnerID:     &ownerID,
		MemberKey:   mk,
	}

	if err := s.repo.Create(ctx, bubble); err != nil {
		return nil, err
	}
	return bubble, nil
}

func (s *bubbleService) GetBubbleByID(ctx context.Context, id string) (*domain.Bubble, error) {
	if id == "" {
		return nil, errors.New("id cannot be empty")
	}
	return s.repo.GetByID(ctx, id)
}

func (s *bubbleService) GetBubbleByName(ctx context.Context, name string) (*domain.Bubble, error) {
	if name == "" {
		return nil, errors.New("name cannot be empty")
	}
	return s.repo.GetByName(ctx, name)
}

func (s *bubbleService) GetBubbles(ctx context.Context, nameFilter string, sortBy string, limit int) ([]*domain.Bubble, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	return s.repo.GetBubbles(ctx, strings.TrimSpace(nameFilter), strings.TrimSpace(sortBy), limit)
}

func (s *bubbleService) DeleteBubble(ctx context.Context, id string) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}
	return s.repo.Delete(ctx, id)
}

func (s *bubbleService) JoinPersonBubble(ctx context.Context, userID, bubbleID string) error {
	member := &domain.BubbleMember{
		UserID:   userID,
		BubbleID: bubbleID,
		Role:     "member",
	}
	return s.repo.Join(ctx, member)
}

func (s *bubbleService) JoinBubble(ctx context.Context, userID, bubbleID string, memberKey *string) error {

	bubble, err := s.repo.GetByID(ctx, bubbleID)
	if err != nil {
		return err
	}
	if bubble.Type == "PERSON" {
		return errors.New("cannot manually join a personal feed")
	}
	if bubble.Type == "PRIVATE" {
		if bubble.MemberKey != nil && *bubble.MemberKey != "" {
			if memberKey == nil || *memberKey != *bubble.MemberKey {
				return errors.New("invalid member key for private bubble")
			}
		} else {
			// If it's PRIVATE but has no member_key, it's STRICTLY Invite-Only!
			return errors.New("this private bubble is invite-only, you cannot join via a member key")
		}
	}

	member := &domain.BubbleMember{
		UserID:   userID,
		BubbleID: bubbleID,
		Role:     "member",
	}
	return s.repo.Join(ctx, member)
}

func (s *bubbleService) LeaveBubble(ctx context.Context, userID, bubbleID string) error {
	return s.repo.Leave(ctx, userID, bubbleID)
}

func (s *bubbleService) GetBubbleMembers(ctx context.Context, bubbleID string) ([]*domain.BubbleMember, error) {
	return s.repo.GetMembers(ctx, bubbleID)
}

func (s *bubbleService) InviteToBubble(ctx context.Context, inviterID, inviteeID, bubbleID string) error {
	if inviterID == inviteeID {
		return errors.New("you cannot invite yourself to a bubble")
	}

	members, err := s.repo.GetMembers(ctx, bubbleID)
	if err != nil {
		return err
	}
	isAuthorized := false
	for _, m := range members {
		if m.UserID == inviterID && (m.Role == "creator" || m.Role == "admin") {
			isAuthorized = true
			break
		}
	}
	if !isAuthorized {
		return errors.New("unauthorized to invite")
	}

	f, err := s.fRepo.Get(ctx, inviteeID, inviterID)
	if err != nil || f.State != "friend" {
		return errors.New("you can only invite friends")
	}

	isException := false
	for _, id := range f.InviteExceptionBubbles {
		if id == bubbleID {
			isException = true
			break
		}
	}

	shouldAllow := true
	if f.InviteState == "NOCASE" {
		shouldAllow = false
	}

	if isException {
		shouldAllow = !shouldAllow
	}

	if !shouldAllow {
		return errors.New("user does not allow invites to this bubble")
	}

	inv := &domain.BubbleInvitation{
		BubbleID:  bubbleID,
		InviterID: inviterID,
		InviteeID: inviteeID,
	}
	return s.repo.CreateInvitation(ctx, inv)
}

func (s *bubbleService) AcceptInvitation(ctx context.Context, inviteeID, inviteID string) error {
	inv, err := s.repo.GetInvitation(ctx, inviteID)
	if err != nil {
		return errors.New("invitation not found")
	}
	if inv.InviteeID != inviteeID {
		return errors.New("unauthorized")
	}
	if inv.Status != "pending" {
		return errors.New("invitation already processed")
	}

	return s.repo.AcceptInvitationAndJoin(ctx, inviteID, inviteeID, inv.BubbleID)
}

func (s *bubbleService) DeclineInvitation(ctx context.Context, inviteeID, inviteID string) error {
	inv, err := s.repo.GetInvitation(ctx, inviteID)
	if err != nil || inv.InviteeID != inviteeID {
		return errors.New("unauthorized")
	}
	if inv.Status != "pending" {
		return errors.New("invitation already processed")
	}
	return s.repo.UpdateInvitationStatus(ctx, inviteID, "declined")
}

func (s *bubbleService) CheckMembership(ctx context.Context, userID, bubbleID string) (bool, error) {
	if userID == "" || bubbleID == "" {
		return false, nil
	}
	return s.repo.CheckMembership(ctx, userID, bubbleID)
}

func (s *bubbleService) CreatePersonBubble(ctx context.Context, userID, username string) error {
	bubble := &domain.Bubble{
		Name:        "", // Will be inserted as NULL via NULLIF in the repo
		Description: "Personal feed for " + username,
		Type:        "PERSON",
		OwnerID:     &userID,
	}
	return s.repo.Create(ctx, bubble)
}

func (s *bubbleService) GetPersonBubbleByOwnerID(ctx context.Context, ownerID string) (*domain.Bubble, error) {
	if ownerID == "" {
		return nil, errors.New("owner id cannot be empty")
	}
	return s.repo.GetPersonBubbleByOwnerID(ctx, ownerID)
}

func (s *bubbleService) GetUserBubbles(ctx context.Context, targetUserID string, isSelf bool) ([]*domain.Bubble, error) {
	if targetUserID == "" {
		return nil, errors.New("user id cannot be empty")
	}
	return s.repo.GetUserBubbles(ctx, targetUserID, isSelf)
}

func (s *bubbleService) UpdateMemberNotifications(ctx context.Context, userID, bubbleID string, enabled bool) error {
	if userID == "" || bubbleID == "" {
		return errors.New("user and bubble ids are required")
	}
	return s.repo.UpdateMemberNotifications(ctx, userID, bubbleID, enabled)
}
