package postgres

import (
	"bubble-api/internal/domain"
	"context"
	"encoding/json"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
)

type replyRepository struct {
	db *pgxpool.Pool
}

func NewReplyRepository(db *pgxpool.Pool) domain.ReplyRepository {
	return &replyRepository{db: db}
}

func (r *replyRepository) Create(ctx context.Context, reply *domain.Reply) error {
	query := `
		WITH inserted AS (
			INSERT INTO replies (post_id, user_id, content, parent_reply_id) 
			VALUES ($1, $2, $3, $4) 
			RETURNING id, post_id, user_id, content, parent_reply_id, created_at
		)
		SELECT 
			i.id, i.post_id, i.user_id, i.content, i.parent_reply_id, i.created_at,
			u.username, COALESCE(u.first_name, ''), COALESCE(u.last_name, ''), COALESCE(u.profile_picture_url, ''),
			pu.username AS parent_username
		FROM inserted i
		JOIN users u ON u.id = i.user_id
		LEFT JOIN replies pr ON pr.id = i.parent_reply_id
		LEFT JOIN users pu ON pu.id = pr.user_id`
	err := r.db.QueryRow(ctx, query, reply.PostID, reply.UserID, reply.Content, reply.ParentReplyID).Scan(
		&reply.ID, &reply.PostID, &reply.UserID, &reply.Content, &reply.ParentReplyID, &reply.CreatedAt,
		&reply.Username, &reply.FirstName, &reply.LastName, &reply.ProfilePictureURL,
		&reply.ParentUsername,
	)
	if err != nil {
		return err
	}
	reply.ReactionCounts = make(map[string]int)
	reply.LikesCount = 0
	reply.RepliesCount = 0
	return nil
}

func (r *replyRepository) GetByID(ctx context.Context, id string, requestingUserID string) (*domain.Reply, error) {
	query := `
		SELECT 
			r.id, r.post_id, r.user_id, r.content, r.parent_reply_id, r.created_at,
			u.username, COALESCE(u.first_name, ''), COALESCE(u.last_name, ''), COALESCE(u.profile_picture_url, ''),
			pu.username AS parent_username,
			(SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = r.id) as likes_count,
			COALESCE((SELECT json_object_agg(emoji_type, count) FROM (SELECT emoji_type, COUNT(*) as count FROM reply_interactions WHERE reply_id = r.id GROUP BY emoji_type) sub), '{}'::json) as reaction_counts,
			(SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = r.id) as replies_count,
			(SELECT ri.emoji_type FROM reply_interactions ri WHERE ri.reply_id = r.id AND ($2::uuid IS NOT NULL AND ri.user_id = $2::uuid)) as user_emoji
		FROM replies r
		JOIN users u ON u.id = r.user_id
		LEFT JOIN replies pr ON pr.id = r.parent_reply_id
		LEFT JOIN users pu ON pu.id = pr.user_id
		WHERE r.id = $1`
	var p domain.Reply
	var reactionBytes []byte
	var userParam *string
	if requestingUserID != "" {
		userParam = &requestingUserID
	}
	err := r.db.QueryRow(ctx, query, id, userParam).Scan(
		&p.ID, &p.PostID, &p.UserID, &p.Content, &p.ParentReplyID, &p.CreatedAt,
		&p.Username, &p.FirstName, &p.LastName, &p.ProfilePictureURL,
		&p.ParentUsername,
		&p.LikesCount, &reactionBytes, &p.RepliesCount,
		&p.UserEmoji,
	)
	if err != nil {
		return nil, err
	}
	p.ReactionCounts = make(map[string]int)
	if len(reactionBytes) > 0 {
		_ = json.Unmarshal(reactionBytes, &p.ReactionCounts)
	}
	return &p, nil
}

func (r *replyRepository) GetByPostID(ctx context.Context, postID string, requestingUserID string) ([]*domain.Reply, error) {
	query := `
		SELECT 
			r.id, r.post_id, r.user_id, r.content, r.parent_reply_id, r.created_at,
			u.username, COALESCE(u.first_name, ''), COALESCE(u.last_name, ''), COALESCE(u.profile_picture_url, ''),
			pu.username AS parent_username,
			(SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = r.id) as likes_count,
			COALESCE((SELECT json_object_agg(emoji_type, count) FROM (SELECT emoji_type, COUNT(*) as count FROM reply_interactions WHERE reply_id = r.id GROUP BY emoji_type) sub), '{}'::json) as reaction_counts,
			(SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = r.id) as replies_count,
			(SELECT ri.emoji_type FROM reply_interactions ri WHERE ri.reply_id = r.id AND ($2::uuid IS NOT NULL AND ri.user_id = $2::uuid)) as user_emoji
		FROM replies r
		JOIN users u ON u.id = r.user_id
		LEFT JOIN replies pr ON pr.id = r.parent_reply_id
		LEFT JOIN users pu ON pu.id = pr.user_id
		WHERE r.post_id = $1 
		ORDER BY (
			(SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = r.id) +
			(SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = r.id)
		) DESC, r.created_at ASC`
	var userParam *string
	if requestingUserID != "" {
		userParam = &requestingUserID
	}
	rows, err := r.db.Query(ctx, query, postID, userParam)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var replies []*domain.Reply
	for rows.Next() {
		var p domain.Reply
		var reactionBytes []byte
		if err := rows.Scan(
			&p.ID, &p.PostID, &p.UserID, &p.Content, &p.ParentReplyID, &p.CreatedAt,
			&p.Username, &p.FirstName, &p.LastName, &p.ProfilePictureURL,
			&p.ParentUsername,
			&p.LikesCount, &reactionBytes, &p.RepliesCount,
			&p.UserEmoji,
		); err != nil {
			return nil, err
		}
		p.ReactionCounts = make(map[string]int)
		if len(reactionBytes) > 0 {
			_ = json.Unmarshal(reactionBytes, &p.ReactionCounts)
		}
		replies = append(replies, &p)
	}
	return replies, rows.Err()
}

func (r *replyRepository) ReactToReply(ctx context.Context, userID, replyID, emojiType string) error {
	query := `
		INSERT INTO reply_interactions (user_id, reply_id, emoji_type)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id, reply_id) DO UPDATE SET
			emoji_type = EXCLUDED.emoji_type,
			updated_at = CURRENT_TIMESTAMP
	`
	_, err := r.db.Exec(ctx, query, userID, replyID, emojiType)
	return err
}

func (r *replyRepository) RemoveReaction(ctx context.Context, userID, replyID string) error {
	query := `DELETE FROM reply_interactions WHERE user_id = $1 AND reply_id = $2`
	_, err := r.db.Exec(ctx, query, userID, replyID)
	return err
}

func (r *replyRepository) Update(ctx context.Context, reply *domain.Reply) error {
	query := `UPDATE replies SET content = $1 WHERE id = $2`
	result, err := r.db.Exec(ctx, query, reply.Content, reply.ID)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return errors.New("reply not found")
	}
	return nil
}

func (r *replyRepository) Delete(ctx context.Context, id string) error {
	query := `DELETE FROM replies WHERE id = $1`
	result, err := r.db.Exec(ctx, query, id)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return errors.New("reply not found")
	}
	return nil
}
