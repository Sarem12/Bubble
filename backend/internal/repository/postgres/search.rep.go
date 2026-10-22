package postgres

import (
	"bubble-api/internal/domain"
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type searchRepository struct {
	db *pgxpool.Pool
}

func NewSearchRepository(db *pgxpool.Pool) domain.SearchRepository {
	return &searchRepository{db: db}
}

func (r *searchRepository) SearchUsers(ctx context.Context, query string, direct bool, limit int) ([]*domain.UserSearchResult, error) {
	var sql string
	if direct {

		sql = `
			SELECT id, username, bio, type 
			FROM users 
			WHERE type = 'PUBLIC' AND username ILIKE '%' || $1 || '%'
			ORDER BY 
				CASE WHEN username = $1 THEN 1 ELSE 2 END ASC,
				created_at DESC
			LIMIT $2;
		`
	} else {

		sql = `
			SELECT id, username, bio, type 
			FROM users 
			WHERE type = 'PUBLIC' 
			  AND ($1 = '' OR username ILIKE '%' || $1 || '%' OR bio ILIKE '%' || $1 || '%')
			ORDER BY created_at DESC
			LIMIT $2;
		`
	}

	rows, err := r.db.Query(ctx, sql, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []*domain.UserSearchResult
	for rows.Next() {
		var u domain.UserSearchResult
		if err := rows.Scan(&u.ID, &u.Username, &u.Bio, &u.Type); err != nil {
			return nil, err
		}
		results = append(results, &u)
	}
	return results, rows.Err()
}

func (r *searchRepository) SearchBubbles(ctx context.Context, query string, direct bool, limit int) ([]*domain.BubbleSearchResult, error) {
	var sql string
	if direct {

		sql = `
			SELECT id, name, description, type 
			FROM networks 
			WHERE type = 'PUBLIC' AND (name ILIKE '%' || $1 || '%' 
			   OR to_tsvector('english', name) @@ websearch_to_tsquery('english', $1))
			ORDER BY 
				CASE WHEN name = $1 THEN 1 ELSE 2 END ASC,
				created_at DESC
			LIMIT $2;
		`
	} else {
		sql = `
			SELECT id, name, description, type 
			FROM networks 
			WHERE type = 'PUBLIC' 
			  AND ($1 = '' OR to_tsvector('english', name) @@ websearch_to_tsquery('english', NULLIF($1, '')))
			ORDER BY created_at DESC
			LIMIT $2;
		`
	}

	rows, err := r.db.Query(ctx, sql, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []*domain.BubbleSearchResult
	for rows.Next() {
		var b domain.BubbleSearchResult
		if err := rows.Scan(&b.ID, &b.Name, &b.Description, &b.Type); err != nil {
			return nil, err
		}
		results = append(results, &b)
	}
	return results, rows.Err()
}

func (r *searchRepository) SearchPosts(ctx context.Context, query string, limit int) ([]*domain.PostSearchResult, error) {
	sql := `
		SELECT p.id, p.content, 
			   (SELECT COUNT(*) FROM post_interactions r WHERE r.post_id = p.id AND r.emoji_type IS NOT NULL) as likes_count,
			   CASE 
			       WHEN n.type = 'PERSON' THEN '' 
			       ELSE COALESCE(n.name, '') 
			   END AS bubble_name
		FROM posts p
		JOIN networks n ON n.id = p.bubble_id
		WHERE n.type = 'PUBLIC'
		  AND ($1 = '' OR n.name ILIKE '%' || $1 || '%'
		       OR p.content ILIKE '%' || $1 || '%')
		ORDER BY likes_count DESC, p.created_at DESC
		LIMIT $2;
	`

	rows, err := r.db.Query(ctx, sql, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []*domain.PostSearchResult
	for rows.Next() {
		var p domain.PostSearchResult
		if err := rows.Scan(&p.ID, &p.Content, &p.LikesCount, &p.BubbleName); err != nil {
			return nil, err
		}
		results = append(results, &p)
	}
	return results, rows.Err()
}

func (r *searchRepository) GetTopPostsForBubble(ctx context.Context, bubbleName string, limit int) ([]*domain.PostSearchResult, error) {
	sql := `
		SELECT p.id, p.content, 
			   (SELECT COUNT(*) FROM post_interactions r WHERE r.post_id = p.id AND r.emoji_type IS NOT NULL) as likes_count
		FROM posts p
		JOIN networks n ON n.id = p.bubble_id
		WHERE n.type = 'PUBLIC' AND n.name = $1
		ORDER BY likes_count DESC, p.created_at DESC
		LIMIT $2;
	`

	rows, err := r.db.Query(ctx, sql, bubbleName, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []*domain.PostSearchResult
	for rows.Next() {
		var p domain.PostSearchResult
		if err := rows.Scan(&p.ID, &p.Content, &p.LikesCount); err != nil {
			return nil, err
		}
		results = append(results, &p)
	}
	return results, rows.Err()
}
