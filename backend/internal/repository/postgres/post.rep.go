package postgres

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
)

type postRepository struct {
	db *pgxpool.Pool
}

func NewPostRepository(db *pgxpool.Pool) domain.PostRepository {
	return &postRepository{db: db}
}

func (r *postRepository) Create(ctx context.Context, post *domain.Post) error {
	query := `INSERT INTO posts (user_id, bubble_id, content) VALUES ($1, NULLIF($2, '')::UUID, $3) RETURNING id, created_at`
	return r.db.QueryRow(ctx, query, post.UserID, post.BubbleID, post.Content).Scan(&post.ID, &post.CreatedAt)
}

func (r *postRepository) GetByID(ctx context.Context, id string) (*domain.Post, error) {
	query := `
		SELECT 
			p.id, p.user_id, COALESCE(p.bubble_id::text, ''), 
			CASE WHEN n.type = 'PERSON' THEN '' ELSE COALESCE(n.name, '') END,
			p.content, p.created_at
		FROM posts p
		LEFT JOIN networks n ON n.id = p.bubble_id
		WHERE p.id = $1`
	var p domain.Post
	err := r.db.QueryRow(ctx, query, id).Scan(&p.ID, &p.UserID, &p.BubbleID, &p.BubbleName, &p.Content, &p.CreatedAt)
	if err != nil {
		return nil, err
	}
	if p.BubbleID != "" {
		p.BubbleIDs = []string{p.BubbleID}
	}
	return &p, nil
}

func (r *postRepository) GetByBubbleID(ctx context.Context, bubbleID string) ([]*domain.Post, error) {
	query := `
		SELECT 
			p.id, p.user_id, COALESCE(p.bubble_id::text, ''), 
			CASE WHEN n.type = 'PERSON' THEN '' ELSE COALESCE(n.name, '') END,
			p.content, p.created_at
		FROM posts p
		LEFT JOIN networks n ON n.id = p.bubble_id
		WHERE p.bubble_id = $1
		ORDER BY p.created_at DESC`
	rows, err := r.db.Query(ctx, query, bubbleID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var posts []*domain.Post
	for rows.Next() {
		var p domain.Post
		if err := rows.Scan(&p.ID, &p.UserID, &p.BubbleID, &p.BubbleName, &p.Content, &p.CreatedAt); err != nil {
			return nil, err
		}
		if p.BubbleID != "" {
			p.BubbleIDs = []string{p.BubbleID}
		}
		posts = append(posts, &p)
	}
	if posts == nil {
		posts = []*domain.Post{}
	}
	return posts, rows.Err()
}

func (r *postRepository) Update(ctx context.Context, post *domain.Post) error {
	query := `UPDATE posts SET content = $1 WHERE id = $2`
	result, err := r.db.Exec(ctx, query, post.Content, post.ID)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return errors.New("post not found")
	}
	return nil
}

func (r *postRepository) Delete(ctx context.Context, id string) error {
	query := `DELETE FROM posts WHERE id = $1`
	result, err := r.db.Exec(ctx, query, id)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return errors.New("post not found")
	}
	return nil
}

func (r *postRepository) GetUserNotificationSettings(ctx context.Context, userID string) ([]*domain.PostNotificationSettings, error) {
	rows, err := r.db.Query(ctx, `SELECT id, content, reactions_notification, comments_notification, replies_notification FROM posts WHERE user_id = $1 ORDER BY created_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	settings := make([]*domain.PostNotificationSettings, 0)
	for rows.Next() {
		var item domain.PostNotificationSettings
		if err := rows.Scan(&item.PostID, &item.Content, &item.Reactions, &item.Comments, &item.Replies); err != nil {
			return nil, err
		}
		settings = append(settings, &item)
	}
	return settings, rows.Err()
}

func (r *postRepository) UpdateNotificationSettings(ctx context.Context, postID, userID string, params domain.UpdatePostNotificationParams) error {
	result, err := r.db.Exec(ctx, `UPDATE posts SET reactions_notification = COALESCE($1, reactions_notification), comments_notification = COALESCE($2, comments_notification), replies_notification = COALESCE($3, replies_notification) WHERE id = $4 AND user_id = $5`, params.Reactions, params.Comments, params.Replies, postID, userID)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return errors.New("post not found or not owned by user")
	}
	return nil
}
