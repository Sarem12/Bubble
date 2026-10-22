package service

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"strings"
)

type postService struct {
	repo          domain.PostRepository
	mediaRepo     domain.MediaRepository
	bubbleService domain.BubbleService
}

func NewPostService(repo domain.PostRepository, mediaRepo domain.MediaRepository, bubbleService domain.BubbleService) domain.PostService {
	return &postService{repo: repo, mediaRepo: mediaRepo, bubbleService: bubbleService}
}

func (s *postService) CreatePost(ctx context.Context, userID string, bubbleID string, content string, media []domain.PostMediaInput) (*domain.Post, error) {
	if strings.TrimSpace(content) == "" && len(media) == 0 {
		return nil, domain.ErrMissingContent
	}

	// If it's a personal post (empty bubbleID), automatically route it to their PERSON bubble
	if bubbleID == "" {
		personBubble, err := s.bubbleService.GetPersonBubbleByOwnerID(ctx, userID)
		if err != nil {
			if strings.Contains(err.Error(), "no rows") {
				return nil, domain.ErrPersonalBubbleNotFound
			}
			return nil, err
		}
		if personBubble != nil {
			bubbleID = personBubble.ID
		} else {
			return nil, domain.ErrPersonalBubbleNotFound
		}
	} else {
		// SECURITY: Ensure user is a member of the bubble, and prevent posting to other users' PERSON bubbles
		bubble, err := s.bubbleService.GetBubbleByID(ctx, bubbleID)
		if err != nil {
			if strings.Contains(err.Error(), "no rows") {
				return nil, domain.ErrBubbleNotFound
			}
			return nil, err
		}

		if bubble.Type == "PERSON" {
			if bubble.OwnerID == nil || *bubble.OwnerID != userID {
				return nil, domain.ErrCannotPostInOtherPerson
			}
		} else {
			isMember, err := s.bubbleService.CheckMembership(ctx, userID, bubbleID)
			if err != nil || !isMember {
				return nil, domain.ErrMustJoinAll
			}
		}
	}

	post := &domain.Post{
		UserID:    userID,
		BubbleID:  bubbleID,
		BubbleIDs: []string{bubbleID},
		Content:   content,
	}

	if err := s.repo.Create(ctx, post); err != nil {
		return nil, err
	}

	for _, m := range media {
		pm := &domain.PostMedia{
			PostID:    post.ID,
			MediaType: strings.ToUpper(m.MediaType),
			URL:       m.URL,
		}
		_ = s.mediaRepo.AddMediaToPost(ctx, pm)
		post.Media = append(post.Media, pm)
	}

	return post, nil
}

func (s *postService) GetPostByID(ctx context.Context, id, userID string) (*domain.Post, error) {
	p, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	// SECURITY: Check bubble privacy
	var isAuthorized bool
	if p.BubbleID != "" {
		bubble, err := s.bubbleService.GetBubbleByID(ctx, p.BubbleID)
		if err == nil {
			if bubble.Type == "PUBLIC" {
				isAuthorized = true
			} else if bubble.Type == "PERSON" {
				if bubble.OwnerID != nil && *bubble.OwnerID == userID {
					isAuthorized = true
				} else if userID != "" {
					isMember, _ := s.bubbleService.CheckMembership(ctx, userID, p.BubbleID)
					if isMember {
						isAuthorized = true
					}
				}
			} else if userID != "" {
				isMember, _ := s.bubbleService.CheckMembership(ctx, userID, p.BubbleID)
				if isMember {
					isAuthorized = true
				}
			}
		}
	} else {
		isAuthorized = true
	}

	if !isAuthorized {
		return nil, errors.New("you do not have permission to view this post")
	}

	media, _ := s.mediaRepo.GetMediaByPostID(ctx, id)
	p.Media = media
	return p, nil
}

func (s *postService) GetPostsByBubbleID(ctx context.Context, bubbleID, userID string) ([]*domain.Post, error) {
	// SECURITY: Check bubble privacy
	bubble, err := s.bubbleService.GetBubbleByID(ctx, bubbleID)
	if err != nil {
		return nil, errors.New("bubble not found")
	}

	if bubble.Type == "PRIVATE" {
		if userID == "" {
			return nil, errors.New("you must be logged in to view a private bubble")
		}
		isMember, err := s.bubbleService.CheckMembership(ctx, userID, bubbleID)
		if err != nil || !isMember {
			return nil, errors.New("you must join this private bubble to view its posts")
		}
	}

	posts, err := s.repo.GetByBubbleID(ctx, bubbleID)
	if err == nil {
		for _, p := range posts {
			media, _ := s.mediaRepo.GetMediaByPostID(ctx, p.ID)
			p.Media = media
		}
	}
	return posts, err
}

func (s *postService) UpdatePost(ctx context.Context, id, userID, content string) (*domain.Post, error) {
	post, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if post.UserID != userID {
		return nil, errors.New("unauthorized to update post")
	}

	post.Content = content
	if err := s.repo.Update(ctx, post); err != nil {
		return nil, err
	}
	return post, nil
}

func (s *postService) DeletePost(ctx context.Context, id, userID string) error {
	post, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if post.UserID != userID {
		return errors.New("unauthorized to delete post")
	}
	return s.repo.Delete(ctx, id)
}

func (s *postService) GetUserNotificationSettings(ctx context.Context, userID string) ([]*domain.PostNotificationSettings, error) {
	if userID == "" {
		return nil, errors.New("user id is required")
	}
	return s.repo.GetUserNotificationSettings(ctx, userID)
}

func (s *postService) UpdatePostNotificationSettings(ctx context.Context, postID, userID string, params domain.UpdatePostNotificationParams) error {
	valid := func(value *string) bool {
		return value == nil || *value == "AUTOMATIC" || *value == "ON" || *value == "OFF"
	}
	if !valid(params.Reactions) || !valid(params.Comments) || !valid(params.Replies) {
		return errors.New("notification values must be AUTOMATIC, ON, or OFF")
	}
	return s.repo.UpdateNotificationSettings(ctx, postID, userID, params)
}
