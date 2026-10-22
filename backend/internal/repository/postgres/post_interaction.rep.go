package postgres

import (
	"bubble-api/internal/domain"
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type postInteractionRepository struct {
	db *pgxpool.Pool
}

func NewPostInteractionRepository(db *pgxpool.Pool) domain.PostInteractionRepository {
	return &postInteractionRepository{
		db: db,
	}
}

func (r *postInteractionRepository) UpsertReaction(ctx context.Context, interaction *domain.PostInteraction) (*domain.PostInteraction, error) {
	query := `
		INSERT INTO post_interactions (user_id, post_id, emoji_type)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, post_id) DO UPDATE SET
			emoji_type = EXCLUDED.emoji_type,
			updated_at = CURRENT_TIMESTAMP
		RETURNING user_id, post_id, emoji_type, is_saved, is_shared, last_viewed_at, created_at, updated_at
	`
	err := r.db.QueryRow(ctx, query, interaction.UserID, interaction.PostID, interaction.EmojiType).Scan(
		&interaction.UserID, &interaction.PostID, &interaction.EmojiType,
		&interaction.IsSaved, &interaction.IsShared, &interaction.LastViewedAt,
		&interaction.CreatedAt, &interaction.UpdatedAt,
	)
	return interaction, err
}

func (r *postInteractionRepository) UpsertSave(ctx context.Context, interaction *domain.PostInteraction) (*domain.PostInteraction, error) {
	query := `
		INSERT INTO post_interactions (user_id, post_id, is_saved)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, post_id) DO UPDATE SET
			is_saved = EXCLUDED.is_saved,
			updated_at = CURRENT_TIMESTAMP
		RETURNING user_id, post_id, emoji_type, is_saved, is_shared, last_viewed_at, created_at, updated_at
	`
	err := r.db.QueryRow(ctx, query, interaction.UserID, interaction.PostID, interaction.IsSaved).Scan(
		&interaction.UserID, &interaction.PostID, &interaction.EmojiType,
		&interaction.IsSaved, &interaction.IsShared, &interaction.LastViewedAt,
		&interaction.CreatedAt, &interaction.UpdatedAt,
	)
	return interaction, err
}

func (r *postInteractionRepository) UpsertView(ctx context.Context, interaction *domain.PostInteraction) (*domain.PostInteraction, error) {
	query := `
		INSERT INTO post_interactions (user_id, post_id, last_viewed_at)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, post_id) DO UPDATE SET
			last_viewed_at = EXCLUDED.last_viewed_at,
			updated_at = CURRENT_TIMESTAMP
		RETURNING user_id, post_id, emoji_type, is_saved, is_shared, last_viewed_at, created_at, updated_at
	`
	err := r.db.QueryRow(ctx, query, interaction.UserID, interaction.PostID, interaction.LastViewedAt).Scan(
		&interaction.UserID, &interaction.PostID, &interaction.EmojiType,
		&interaction.IsSaved, &interaction.IsShared, &interaction.LastViewedAt,
		&interaction.CreatedAt, &interaction.UpdatedAt,
	)
	return interaction, err
}

func (r *postInteractionRepository) GetInteraction(ctx context.Context, userID, postID string) (*domain.PostInteraction, error) {
	query := `SELECT user_id, post_id, emoji_type, last_viewed_at, is_saved, is_shared, created_at, updated_at FROM post_interactions WHERE user_id = $1 AND post_id = $2`
	var i domain.PostInteraction
	err := r.db.QueryRow(ctx, query, userID, postID).Scan(&i.UserID, &i.PostID, &i.EmojiType, &i.LastViewedAt, &i.IsSaved, &i.IsShared, &i.CreatedAt, &i.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &i, nil
}

func (r *postInteractionRepository) GetInteractionsByPost(ctx context.Context, postID string) ([]*domain.PostInteraction, error) {
	query := `SELECT user_id, post_id, emoji_type, last_viewed_at, is_saved, is_shared, created_at, updated_at FROM post_interactions WHERE post_id = $1`
	rows, err := r.db.Query(ctx, query, postID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var interactions []*domain.PostInteraction
	for rows.Next() {
		var i domain.PostInteraction
		if err := rows.Scan(&i.UserID, &i.PostID, &i.EmojiType, &i.LastViewedAt, &i.IsSaved, &i.IsShared, &i.CreatedAt, &i.UpdatedAt); err != nil {
			return nil, err
		}
		interactions = append(interactions, &i)
	}
	return interactions, rows.Err()
}

func (r *postInteractionRepository) RemoveReaction(ctx context.Context, userID, postID string) error {

	query := `UPDATE post_interactions SET emoji_type = NULL, updated_at = CURRENT_TIMESTAMP WHERE user_id = $1 AND post_id = $2`
	_, err := r.db.Exec(ctx, query, userID, postID)
	return err
}

func (r *postInteractionRepository) UpsertShare(ctx context.Context, interaction *domain.PostInteraction) (*domain.PostInteraction, error) {
	query := `
		INSERT INTO post_interactions (user_id, post_id, is_shared)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, post_id) DO UPDATE SET
			is_shared = EXCLUDED.is_shared,
			updated_at = CURRENT_TIMESTAMP
		RETURNING user_id, post_id, emoji_type, is_saved, is_shared, last_viewed_at, created_at, updated_at
	`
	err := r.db.QueryRow(ctx, query, interaction.UserID, interaction.PostID, interaction.IsShared).Scan(
		&interaction.UserID, &interaction.PostID, &interaction.EmojiType,
		&interaction.IsSaved, &interaction.IsShared, &interaction.LastViewedAt,
		&interaction.CreatedAt, &interaction.UpdatedAt,
	)
	return interaction, err
}
