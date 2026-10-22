package postgres

import (
	"bubble-api/internal/domain"
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type mediaRepository struct {
	db *pgxpool.Pool
}

func NewMediaRepository(db *pgxpool.Pool) domain.MediaRepository {
	return &mediaRepository{db: db}
}

func (r *mediaRepository) AddMediaToPost(ctx context.Context, media *domain.PostMedia) error {
	query := `
		INSERT INTO post_media (post_id, media_type, url)
		VALUES ($1, $2, $3)
		RETURNING id, created_at
	`
	return r.db.QueryRow(ctx, query, media.PostID, media.MediaType, media.URL).Scan(&media.ID, &media.CreatedAt)
}

func (r *mediaRepository) GetMediaByPostID(ctx context.Context, postID string) ([]*domain.PostMedia, error) {
	query := `
		SELECT id, post_id, media_type, url, created_at
		FROM post_media
		WHERE post_id = $1
		ORDER BY created_at ASC
	`
	rows, err := r.db.Query(ctx, query, postID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var mediaList []*domain.PostMedia
	for rows.Next() {
		var m domain.PostMedia
		if err := rows.Scan(&m.ID, &m.PostID, &m.MediaType, &m.URL, &m.CreatedAt); err != nil {
			return nil, err
		}
		mediaList = append(mediaList, &m)
	}
	return mediaList, rows.Err()
}

func (r *mediaRepository) DeleteMedia(ctx context.Context, id string) error {
	query := `DELETE FROM post_media WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	return err
}

func (r *mediaRepository) GetMediaByURL(ctx context.Context, url string) (*domain.PostMedia, error) {
	query := `SELECT id, post_id, media_type, url, created_at FROM post_media WHERE url LIKE '%' || $1`
	var m domain.PostMedia
	err := r.db.QueryRow(ctx, query, url).Scan(&m.ID, &m.PostID, &m.MediaType, &m.URL, &m.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &m, nil
}
