package postgres

import (
	"bubble-api/internal/domain"
	"context"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type activityRepository struct {
	db *pgxpool.Pool
}

func NewActivityRepository(db *pgxpool.Pool) domain.ActivityRepository {
	return &activityRepository{db: db}
}

func (r *activityRepository) GetActivities(ctx context.Context, userID string, limit int, offset int) ([]*domain.ActivityItem, error) {
	if limit <= 0 {
		limit = 30
	}
	if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}

	queryCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	query := `
		WITH user_activities AS (
			-- 1. Post reactions
			SELECT 
				'post_reaction_' || pi.user_id::text || '_' || pi.post_id::text AS id,
				'post_reaction' AS type,
				u.id::text AS actor_id,
				u.username::text AS actor_username,
				COALESCE(u.first_name, '')::text AS actor_first_name,
				COALESCE(u.last_name, '')::text AS actor_last_name,
				COALESCE(u.profile_picture_url, '')::text AS actor_avatar,
				p.id::text AS post_id,
				p.content::text AS post_content,
				(SELECT pm.url::text FROM post_media pm WHERE pm.post_id = p.id ORDER BY pm.created_at ASC LIMIT 1) AS post_media_url,
				NULL::text AS reply_id,
				NULL::text AS reply_content,
				NULL::text AS parent_reply_id,
				pi.emoji_type::text AS emoji,
				NULL::text AS state,
				COALESCE(pi.updated_at, pi.created_at, CURRENT_TIMESTAMP) AS created_at
			FROM post_interactions pi
			JOIN posts p ON pi.post_id = p.id
			JOIN users u ON pi.user_id = u.id
			WHERE p.user_id = $1::uuid 
			  AND pi.user_id != $1::uuid
			  AND pi.emoji_type IS NOT NULL
			  AND pi.emoji_type != ''
			  AND (p.reactions_notification IS NULL OR p.reactions_notification != 'OFF')
			  AND NOT EXISTS (
				  SELECT 1 FROM friendships b 
				  WHERE ((b.source_user_id = $1::uuid AND b.target_user_id = u.id) 
					  OR (b.source_user_id = u.id AND b.target_user_id = $1::uuid)) 
					AND b.state = 'blocked'
			  )

			UNION ALL

			-- 2. Post replies (top-level comments on post)
			SELECT
				'post_reply_' || r.id::text AS id,
				'post_reply' AS type,
				u.id::text AS actor_id,
				u.username::text AS actor_username,
				COALESCE(u.first_name, '')::text AS actor_first_name,
				COALESCE(u.last_name, '')::text AS actor_last_name,
				COALESCE(u.profile_picture_url, '')::text AS actor_avatar,
				p.id::text AS post_id,
				p.content::text AS post_content,
				(SELECT pm.url::text FROM post_media pm WHERE pm.post_id = p.id ORDER BY pm.created_at ASC LIMIT 1) AS post_media_url,
				r.id::text AS reply_id,
				r.content::text AS reply_content,
				NULL::text AS parent_reply_id,
				NULL::text AS emoji,
				NULL::text AS state,
				COALESCE(r.created_at, CURRENT_TIMESTAMP) AS created_at
			FROM replies r
			JOIN posts p ON r.post_id = p.id
			JOIN users u ON r.user_id = u.id
			WHERE p.user_id = $1::uuid 
			  AND r.user_id != $1::uuid
			  AND r.parent_reply_id IS NULL
			  AND (p.comments_notification IS NULL OR p.comments_notification != 'OFF')
			  AND NOT EXISTS (
				  SELECT 1 FROM friendships b 
				  WHERE ((b.source_user_id = $1::uuid AND b.target_user_id = u.id) 
					  OR (b.source_user_id = u.id AND b.target_user_id = $1::uuid)) 
					AND b.state = 'blocked'
			  )

			UNION ALL

			-- 3. Comment replies (nested replies on user's comment)
			SELECT
				'comment_reply_' || r.id::text AS id,
				'comment_reply' AS type,
				u.id::text AS actor_id,
				u.username::text AS actor_username,
				COALESCE(u.first_name, '')::text AS actor_first_name,
				COALESCE(u.last_name, '')::text AS actor_last_name,
				COALESCE(u.profile_picture_url, '')::text AS actor_avatar,
				p.id::text AS post_id,
				p.content::text AS post_content,
				(SELECT pm.url::text FROM post_media pm WHERE pm.post_id = p.id ORDER BY pm.created_at ASC LIMIT 1) AS post_media_url,
				r.id::text AS reply_id,
				r.content::text AS reply_content,
				parent.id::text AS parent_reply_id,
				NULL::text AS emoji,
				NULL::text AS state,
				COALESCE(r.created_at, CURRENT_TIMESTAMP) AS created_at
			FROM replies r
			JOIN replies parent ON r.parent_reply_id = parent.id
			JOIN posts p ON r.post_id = p.id
			JOIN users u ON r.user_id = u.id
			WHERE parent.user_id = $1::uuid 
			  AND r.user_id != $1::uuid
			  AND (p.replies_notification IS NULL OR p.replies_notification != 'OFF')
			  AND NOT EXISTS (
				  SELECT 1 FROM friendships b 
				  WHERE ((b.source_user_id = $1::uuid AND b.target_user_id = u.id) 
					  OR (b.source_user_id = u.id AND b.target_user_id = $1::uuid)) 
					AND b.state = 'blocked'
			  )

			UNION ALL

			-- 4. Reply reactions (reactions on user's reply)
			SELECT
				'reply_reaction_' || ri.user_id::text || '_' || ri.reply_id::text AS id,
				'reply_reaction' AS type,
				u.id::text AS actor_id,
				u.username::text AS actor_username,
				COALESCE(u.first_name, '')::text AS actor_first_name,
				COALESCE(u.last_name, '')::text AS actor_last_name,
				COALESCE(u.profile_picture_url, '')::text AS actor_avatar,
				p.id::text AS post_id,
				p.content::text AS post_content,
				(SELECT pm.url::text FROM post_media pm WHERE pm.post_id = p.id ORDER BY pm.created_at ASC LIMIT 1) AS post_media_url,
				r.id::text AS reply_id,
				r.content::text AS reply_content,
				NULL::text AS parent_reply_id,
				ri.emoji_type::text AS emoji,
				NULL::text AS state,
				COALESCE(ri.updated_at, ri.created_at, CURRENT_TIMESTAMP) AS created_at
			FROM reply_interactions ri
			JOIN replies r ON ri.reply_id = r.id
			JOIN posts p ON r.post_id = p.id
			JOIN users u ON ri.user_id = u.id
			WHERE r.user_id = $1::uuid 
			  AND ri.user_id != $1::uuid
			  AND NOT EXISTS (
				  SELECT 1 FROM friendships b 
				  WHERE ((b.source_user_id = $1::uuid AND b.target_user_id = u.id) 
					  OR (b.source_user_id = u.id AND b.target_user_id = $1::uuid)) 
					AND b.state = 'blocked'
			  )

			UNION ALL

			-- 5. Friend requests
			SELECT
				'friend_request_' || f.target_user_id::text AS id,
				'friend_request' AS type,
				u.id::text AS actor_id,
				u.username::text AS actor_username,
				COALESCE(u.first_name, '')::text AS actor_first_name,
				COALESCE(u.last_name, '')::text AS actor_last_name,
				COALESCE(u.profile_picture_url, '')::text AS actor_avatar,
				NULL::text AS post_id,
				NULL::text AS post_content,
				NULL::text AS post_media_url,
				NULL::text AS reply_id,
				NULL::text AS reply_content,
				NULL::text AS parent_reply_id,
				NULL::text AS emoji,
				f.state::text AS state,
				COALESCE(f.created_at, CURRENT_TIMESTAMP) AS created_at
			FROM friendships f
			JOIN users u ON f.target_user_id = u.id
			WHERE f.source_user_id = $1::uuid 
			  AND f.state = 'request_received'
			  AND NOT EXISTS (
				  SELECT 1 FROM friendships b 
				  WHERE ((b.source_user_id = $1::uuid AND b.target_user_id = u.id) 
					  OR (b.source_user_id = u.id AND b.target_user_id = $1::uuid)) 
					AND b.state = 'blocked'
			  )

			UNION ALL

			-- 6. Friend accepted
			SELECT
				'friend_accepted_' || f.target_user_id::text AS id,
				'friend_accepted' AS type,
				u.id::text AS actor_id,
				u.username::text AS actor_username,
				COALESCE(u.first_name, '')::text AS actor_first_name,
				COALESCE(u.last_name, '')::text AS actor_last_name,
				COALESCE(u.profile_picture_url, '')::text AS actor_avatar,
				NULL::text AS post_id,
				NULL::text AS post_content,
				NULL::text AS post_media_url,
				NULL::text AS reply_id,
				NULL::text AS reply_content,
				NULL::text AS parent_reply_id,
				NULL::text AS emoji,
				f.state::text AS state,
				COALESCE(f.updated_at, f.created_at, CURRENT_TIMESTAMP) AS created_at
			FROM friendships f
			JOIN users u ON f.target_user_id = u.id
			WHERE f.source_user_id = $1::uuid 
			  AND f.state = 'friend'
			  AND f.updated_at > f.created_at
			  AND NOT EXISTS (
				  SELECT 1 FROM friendships b 
				  WHERE ((b.source_user_id = $1::uuid AND b.target_user_id = u.id) 
					  OR (b.source_user_id = u.id AND b.target_user_id = $1::uuid)) 
					AND b.state = 'blocked'
			  )
		)
		SELECT 
			id, type, actor_id, actor_username, actor_first_name, actor_last_name, actor_avatar,
			post_id, post_content, post_media_url, reply_id, reply_content, parent_reply_id,
			emoji, state, created_at
		FROM user_activities
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.Query(queryCtx, query, userID, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var activities []*domain.ActivityItem
	for rows.Next() {
		var item domain.ActivityItem
		if err := rows.Scan(
			&item.ID,
			&item.Type,
			&item.ActorID,
			&item.ActorUsername,
			&item.ActorFirstName,
			&item.ActorLastName,
			&item.ActorAvatar,
			&item.PostID,
			&item.PostContent,
			&item.PostMediaURL,
			&item.ReplyID,
			&item.ReplyContent,
			&item.ParentReplyID,
			&item.Emoji,
			&item.State,
			&item.CreatedAt,
		); err != nil {
			return nil, err
		}
		activities = append(activities, &item)
	}

	if activities == nil {
		activities = []*domain.ActivityItem{}
	}
	return activities, rows.Err()
}

func (r *activityRepository) GetPendingFriendRequests(ctx context.Context, userID string) ([]*domain.FriendRequestItem, error) {
	queryCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	query := `
		SELECT
			f.target_user_id::text AS id,
			f.target_user_id::text AS user_id,
			u.username,
			COALESCE(u.first_name, '') AS first_name,
			COALESCE(u.last_name, '') AS last_name,
			COALESCE(u.profile_picture_url, '') AS profile_picture_url,
			COALESCE(f.created_at, CURRENT_TIMESTAMP) AS created_at
		FROM friendships f
		JOIN users u ON f.target_user_id = u.id
		WHERE f.source_user_id = $1::uuid 
		  AND f.state = 'request_received'
		  AND NOT EXISTS (
			  SELECT 1 FROM friendships b 
			  WHERE ((b.source_user_id = $1::uuid AND b.target_user_id = u.id) 
				  OR (b.source_user_id = u.id AND b.target_user_id = $1::uuid)) 
				AND b.state = 'blocked'
		  )
		ORDER BY f.created_at DESC
	`

	rows, err := r.db.Query(queryCtx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reqs []*domain.FriendRequestItem
	for rows.Next() {
		var req domain.FriendRequestItem
		if err := rows.Scan(
			&req.ID,
			&req.UserID,
			&req.Username,
			&req.FirstName,
			&req.LastName,
			&req.ProfilePictureURL,
			&req.CreatedAt,
		); err != nil {
			return nil, err
		}
		reqs = append(reqs, &req)
	}

	if reqs == nil {
		reqs = []*domain.FriendRequestItem{}
	}
	return reqs, rows.Err()
}
