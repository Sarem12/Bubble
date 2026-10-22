package postgres

import (
	"bubble-api/internal/domain"
	"context"
	"encoding/json"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type feedRepository struct {
	db *pgxpool.Pool
}

func NewFeedRepository(db *pgxpool.Pool) domain.FeedRepository {
	return &feedRepository{db: db}
}

func (r *feedRepository) GetFeed(ctx context.Context, userID string, cursorTime time.Time, cursorID string, limit int) ([]*domain.FeedItem, error) {
	query := `
		SELECT 
			p.id, p.content, p.created_at,
			u.id as author_id, u.username as author_username,
			COALESCE(u.first_name, '') as author_first_name,
			COALESCE(u.last_name, '') as author_last_name,
			u.profile_picture_url,
			COALESCE(n.id::text, '') as bubble_id,
			CASE 
				WHEN n.type = 'PERSON' THEN '' 
				ELSE COALESCE(n.name, '') 
			END as bubble_name,
			(SELECT COUNT(*) FROM post_interactions i WHERE i.post_id = p.id AND i.emoji_type IS NOT NULL) as likes_count,
			COALESCE((SELECT json_object_agg(emoji_type, count) FROM (SELECT emoji_type, COUNT(*) as count FROM post_interactions WHERE post_id = p.id AND emoji_type IS NOT NULL GROUP BY emoji_type) sub), '{}'::json) as reaction_counts,
			(SELECT COUNT(*) FROM replies r WHERE r.post_id = p.id) as replies_count,
			pi.emoji_type as user_emoji,
			COALESCE(
				(SELECT json_agg(json_build_object('id', pm.id, 'post_id', pm.post_id, 'media_type', pm.media_type, 'url', pm.url, 'created_at', pm.created_at))
				 FROM post_media pm WHERE pm.post_id = p.id),
				'[]'::json
			) as media,
			(
				SELECT json_build_object(
					'id', tc.id,
					'post_id', tc.post_id,
					'user_id', tc.user_id,
					'username', tcu.username,
					'first_name', COALESCE(tcu.first_name, ''),
					'last_name', COALESCE(tcu.last_name, ''),
					'profile_picture_url', COALESCE(tcu.profile_picture_url, ''),
					'content', tc.content,
					'created_at', tc.created_at,
					'likes_count', (SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = tc.id),
					'replies_count', (SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = tc.id)
				)
				FROM replies tc
				JOIN users tcu ON tcu.id = tc.user_id
				WHERE tc.post_id = p.id
				ORDER BY (
					(SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = tc.id) +
					(SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = tc.id)
				) DESC, tc.created_at ASC
				LIMIT 1
			) as top_comment
		FROM posts p
		JOIN users u ON p.user_id = u.id
		LEFT JOIN networks n ON n.id = p.bubble_id
		LEFT JOIN post_interactions pi ON pi.post_id = p.id AND pi.user_id = $1
		WHERE pi.last_viewed_at IS NULL
		  AND p.user_id != $1
		  AND ($2::TIMESTAMP IS NULL OR p.created_at < $2 OR (p.created_at = $2 AND p.id < $3))
		  AND (
		      n.id IS NULL 
		      OR n.type = 'PERSON'
		      OR n.type = 'PUBLIC' 
		      OR EXISTS (SELECT 1 FROM network_members nm WHERE nm.network_id = n.id AND nm.user_id = $1)
		  )
		  AND NOT EXISTS (
		      SELECT 1 FROM friendships f 
		      WHERE f.source_user_id = $1 
		        AND f.target_user_id = p.user_id 
		        AND f.ignore_in_feed = true
		  )
		  AND NOT EXISTS (
		      SELECT 1 FROM friendships f 
		      WHERE ((f.source_user_id = $1 AND f.target_user_id = p.user_id) 
		         OR (f.source_user_id = p.user_id AND f.target_user_id = $1))
		        AND f.state = 'blocked'
		  )
		ORDER BY p.created_at DESC, p.id DESC
		LIMIT $4
	`

	var cursorTimeVal interface{}
	if !cursorTime.IsZero() {
		cursorTimeVal = cursorTime
	}

	var cursorIDVal interface{}
	if cursorID != "" {
		cursorIDVal = cursorID
	}

	rows, err := r.db.Query(ctx, query, userID, cursorTimeVal, cursorIDVal, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var feed []*domain.FeedItem
	for rows.Next() {
		var item domain.FeedItem
		var mediaBytes []byte
		var reactionBytes []byte
		var topCommentBytes []byte
		if err := rows.Scan(
			&item.ID, &item.Content, &item.CreatedAt,
			&item.AuthorID, &item.AuthorUsername, &item.AuthorFirstName, &item.AuthorLastName, &item.AuthorPicture,
			&item.BubbleID, &item.BubbleName,
			&item.LikesCount, &reactionBytes, &item.RepliesCount,
			&item.UserEmoji,
			&mediaBytes,
			&topCommentBytes,
		); err != nil {
			return nil, err
		}

		if len(mediaBytes) > 0 {
			if err := json.Unmarshal(mediaBytes, &item.Media); err != nil {
				return nil, err
			}
		}
		if len(reactionBytes) > 0 {
			if err := json.Unmarshal(reactionBytes, &item.ReactionCounts); err != nil {
				return nil, err
			}
		}
		if len(topCommentBytes) > 0 {
			if err := json.Unmarshal(topCommentBytes, &item.TopComment); err != nil {
				return nil, err
			}
		}
		feed = append(feed, &item)
	}
	return feed, rows.Err()
}

func (r *feedRepository) GetFeedItem(ctx context.Context, userID, postID string) (*domain.FeedItem, error) {
	query := `
		SELECT 
			p.id, p.content, p.created_at,
			u.id as author_id, u.username as author_username,
			COALESCE(u.first_name, '') as author_first_name,
			COALESCE(u.last_name, '') as author_last_name,
			u.profile_picture_url,
			COALESCE(n.id::text, '') as bubble_id,
			CASE 
				WHEN n.type = 'PERSON' THEN '' 
				ELSE COALESCE(n.name, '') 
			END as bubble_name,
			(SELECT COUNT(*) FROM post_interactions i WHERE i.post_id = p.id AND i.emoji_type IS NOT NULL) as likes_count,
			COALESCE((SELECT json_object_agg(emoji_type, count) FROM (SELECT emoji_type, COUNT(*) as count FROM post_interactions WHERE post_id = p.id AND emoji_type IS NOT NULL GROUP BY emoji_type) sub), '{}'::json) as reaction_counts,
			(SELECT COUNT(*) FROM replies r WHERE r.post_id = p.id) as replies_count,
			pi.emoji_type as user_emoji,
			COALESCE(
				(SELECT json_agg(json_build_object('id', pm.id, 'post_id', pm.post_id, 'media_type', pm.media_type, 'url', pm.url, 'created_at', pm.created_at))
				 FROM post_media pm WHERE pm.post_id = p.id),
				'[]'::json
			) as media,
			(
				SELECT json_build_object(
					'id', tc.id,
					'post_id', tc.post_id,
					'user_id', tc.user_id,
					'username', tcu.username,
					'first_name', COALESCE(tcu.first_name, ''),
					'last_name', COALESCE(tcu.last_name, ''),
					'profile_picture_url', COALESCE(tcu.profile_picture_url, ''),
					'content', tc.content,
					'created_at', tc.created_at,
					'likes_count', (SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = tc.id),
					'replies_count', (SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = tc.id)
				)
				FROM replies tc
				JOIN users tcu ON tcu.id = tc.user_id
				WHERE tc.post_id = p.id
				ORDER BY (
					(SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = tc.id) +
					(SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = tc.id)
				) DESC, tc.created_at ASC
				LIMIT 1
			) as top_comment
		FROM posts p
		JOIN users u ON p.user_id = u.id
		LEFT JOIN networks n ON n.id = p.bubble_id
		LEFT JOIN post_interactions pi ON pi.post_id = p.id AND pi.user_id = $1
		WHERE p.id = $2
		  AND (
		      n.id IS NULL
		      OR n.type = 'PERSON'
		      OR n.type = 'PUBLIC'
		      OR p.user_id = $1
		      OR EXISTS (SELECT 1 FROM network_members nm WHERE nm.network_id = n.id AND nm.user_id = $1)
		  )
	`

	var item domain.FeedItem
	var mediaBytes []byte
	var reactionBytes []byte
	var topCommentBytes []byte
	err := r.db.QueryRow(ctx, query, userID, postID).Scan(
		&item.ID, &item.Content, &item.CreatedAt,
		&item.AuthorID, &item.AuthorUsername, &item.AuthorFirstName, &item.AuthorLastName, &item.AuthorPicture,
		&item.BubbleID, &item.BubbleName,
		&item.LikesCount, &reactionBytes, &item.RepliesCount,
		&item.UserEmoji,
		&mediaBytes,
		&topCommentBytes,
	)
	if err != nil {
		return nil, err
	}

	if len(mediaBytes) > 0 {
		if err := json.Unmarshal(mediaBytes, &item.Media); err != nil {
			return nil, err
		}
	}
	if len(reactionBytes) > 0 {
		if err := json.Unmarshal(reactionBytes, &item.ReactionCounts); err != nil {
			return nil, err
		}
	}
	if len(topCommentBytes) > 0 {
		if err := json.Unmarshal(topCommentBytes, &item.TopComment); err != nil {
			return nil, err
		}
	}

	return &item, nil
}

func (r *feedRepository) GetExploreFeed(ctx context.Context, userID string, limit int) ([]*domain.FeedItem, error) {
	query := `
		SELECT 
			p.id, p.content, p.created_at,
			u.id as author_id, u.username as author_username,
			COALESCE(u.first_name, '') as author_first_name,
			COALESCE(u.last_name, '') as author_last_name,
			u.profile_picture_url,
			COALESCE(n.id::text, '') as bubble_id,
			CASE 
				WHEN n.type = 'PERSON' THEN '' 
				ELSE COALESCE(n.name, '') 
			END as bubble_name,
			(SELECT COUNT(*) FROM post_interactions i WHERE i.post_id = p.id AND i.emoji_type IS NOT NULL) as likes_count,
			COALESCE((SELECT json_object_agg(emoji_type, count) FROM (SELECT emoji_type, COUNT(*) as count FROM post_interactions WHERE post_id = p.id AND emoji_type IS NOT NULL GROUP BY emoji_type) sub), '{}'::json) as reaction_counts,
			(SELECT COUNT(*) FROM replies r WHERE r.post_id = p.id) as replies_count,
			pi.emoji_type as user_emoji,
			COALESCE(
				(SELECT json_agg(json_build_object('id', pm.id, 'post_id', pm.post_id, 'media_type', pm.media_type, 'url', pm.url, 'created_at', pm.created_at))
				 FROM post_media pm WHERE pm.post_id = p.id),
				'[]'::json
			) as media,
			(
				SELECT json_build_object(
					'id', tc.id,
					'post_id', tc.post_id,
					'user_id', tc.user_id,
					'username', tcu.username,
					'first_name', COALESCE(tcu.first_name, ''),
					'last_name', COALESCE(tcu.last_name, ''),
					'profile_picture_url', COALESCE(tcu.profile_picture_url, ''),
					'content', tc.content,
					'created_at', tc.created_at,
					'likes_count', (SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = tc.id),
					'replies_count', (SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = tc.id)
				)
				FROM replies tc
				JOIN users tcu ON tcu.id = tc.user_id
				WHERE tc.post_id = p.id
				ORDER BY (
					(SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = tc.id) +
					(SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = tc.id)
				) DESC, tc.created_at ASC
				LIMIT 1
			) as top_comment
		FROM posts p
		JOIN users u ON p.user_id = u.id
		JOIN networks n ON n.id = p.bubble_id
		LEFT JOIN post_interactions pi ON pi.post_id = p.id AND pi.user_id = $1
		WHERE n.type = 'PUBLIC'
		  AND p.user_id != $1
		  AND NOT EXISTS (
			SELECT 1 FROM network_members nm WHERE nm.network_id = n.id AND nm.user_id = $1
		  ) AND pi.emoji_type IS NULL AND pi.last_viewed_at IS NULL
		ORDER BY (
				(SELECT COUNT(*) FROM post_interactions i WHERE i.post_id = p.id AND i.emoji_type IS NOT NULL) +
				(SELECT COUNT(*) FROM post_interactions i WHERE i.post_id = p.id AND i.is_shared = true)
			) DESC, p.created_at DESC
		LIMIT $2
	`

	rows, err := r.db.Query(ctx, query, userID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var feed []*domain.FeedItem
	for rows.Next() {
		var item domain.FeedItem
		var mediaBytes []byte
		var reactionBytes []byte
		var topCommentBytes []byte
		if err := rows.Scan(
			&item.ID, &item.Content, &item.CreatedAt,
			&item.AuthorID, &item.AuthorUsername, &item.AuthorFirstName, &item.AuthorLastName, &item.AuthorPicture,
			&item.BubbleID, &item.BubbleName,
			&item.LikesCount, &reactionBytes, &item.RepliesCount,
			&item.UserEmoji,
			&mediaBytes,
			&topCommentBytes,
		); err != nil {
			return nil, err
		}

		if len(mediaBytes) > 0 {
			if err := json.Unmarshal(mediaBytes, &item.Media); err != nil {
				return nil, err
			}
		}
		if len(reactionBytes) > 0 {
			if err := json.Unmarshal(reactionBytes, &item.ReactionCounts); err != nil {
				return nil, err
			}
		}
		if len(topCommentBytes) > 0 {
			if err := json.Unmarshal(topCommentBytes, &item.TopComment); err != nil {
				return nil, err
			}
		}
		feed = append(feed, &item)
	}
	return feed, rows.Err()
}

func (r *feedRepository) GetUserFeed(ctx context.Context, requestingUserID string, targetUserID string, limit int) ([]*domain.FeedItem, error) {
	query := `
		SELECT 
			p.id, p.content, p.created_at,
			u.id as author_id, u.username as author_username,
			COALESCE(u.first_name, '') as author_first_name,
			COALESCE(u.last_name, '') as author_last_name,
			u.profile_picture_url,
			COALESCE(n.id::text, '') as bubble_id,
			CASE 
				WHEN n.type = 'PERSON' THEN '' 
				ELSE COALESCE(n.name, '') 
			END as bubble_name,
			(SELECT COUNT(*) FROM post_interactions i WHERE i.post_id = p.id AND i.emoji_type IS NOT NULL) as likes_count,
			COALESCE((SELECT json_object_agg(emoji_type, count) FROM (SELECT emoji_type, COUNT(*) as count FROM post_interactions WHERE post_id = p.id AND emoji_type IS NOT NULL GROUP BY emoji_type) sub), '{}'::json) as reaction_counts,
			(SELECT COUNT(*) FROM replies r WHERE r.post_id = p.id) as replies_count,
			pi.emoji_type as user_emoji,
			COALESCE(
				(SELECT json_agg(json_build_object('id', pm.id, 'post_id', pm.post_id, 'media_type', pm.media_type, 'url', pm.url, 'created_at', pm.created_at))
				 FROM post_media pm WHERE pm.post_id = p.id),
				'[]'::json
			) as media,
			(
				SELECT json_build_object(
					'id', tc.id,
					'post_id', tc.post_id,
					'user_id', tc.user_id,
					'username', tcu.username,
					'first_name', COALESCE(tcu.first_name, ''),
					'last_name', COALESCE(tcu.last_name, ''),
					'profile_picture_url', COALESCE(tcu.profile_picture_url, ''),
					'content', tc.content,
					'created_at', tc.created_at,
					'likes_count', (SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = tc.id),
					'replies_count', (SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = tc.id)
				)
				FROM replies tc
				JOIN users tcu ON tcu.id = tc.user_id
				WHERE tc.post_id = p.id
				ORDER BY (
					(SELECT COUNT(*) FROM reply_interactions ri WHERE ri.reply_id = tc.id) +
					(SELECT COUNT(*) FROM replies cr WHERE cr.parent_reply_id = tc.id)
				) DESC, tc.created_at ASC
				LIMIT 1
			) as top_comment
		FROM posts p
		JOIN users u ON p.user_id = u.id
		LEFT JOIN networks n ON n.id = p.bubble_id
		LEFT JOIN post_interactions pi ON pi.post_id = p.id AND pi.user_id = $1
		WHERE p.user_id = $2
		  AND (
		      n.id IS NULL
		      OR n.type = 'PERSON'
		      OR n.type = 'PUBLIC'
		      OR p.user_id = $1
		      OR EXISTS (SELECT 1 FROM network_members nm WHERE nm.network_id = n.id AND nm.user_id = $1)
		  )
		ORDER BY p.created_at DESC, p.id DESC
		LIMIT $3
	`

	rows, err := r.db.Query(ctx, query, requestingUserID, targetUserID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var feed []*domain.FeedItem
	for rows.Next() {
		var item domain.FeedItem
		var mediaBytes []byte
		var reactionBytes []byte
		var bubbleID *string
		var bubbleName *string
		var topCommentBytes []byte
		if err := rows.Scan(
			&item.ID, &item.Content, &item.CreatedAt,
			&item.AuthorID, &item.AuthorUsername, &item.AuthorFirstName, &item.AuthorLastName, &item.AuthorPicture,
			&bubbleID, &bubbleName,
			&item.LikesCount, &reactionBytes, &item.RepliesCount,
			&item.UserEmoji,
			&mediaBytes,
			&topCommentBytes,
		); err != nil {
			return nil, err
		}

		if bubbleID != nil {
			item.BubbleID = *bubbleID
		}
		if bubbleName != nil {
			item.BubbleName = *bubbleName
		}

		if len(mediaBytes) > 0 {
			if err := json.Unmarshal(mediaBytes, &item.Media); err != nil {
				return nil, err
			}
		}
		if len(reactionBytes) > 0 {
			if err := json.Unmarshal(reactionBytes, &item.ReactionCounts); err != nil {
				return nil, err
			}
		}
		if len(topCommentBytes) > 0 {
			if err := json.Unmarshal(topCommentBytes, &item.TopComment); err != nil {
				return nil, err
			}
		}
		feed = append(feed, &item)
	}
	return feed, rows.Err()
}
