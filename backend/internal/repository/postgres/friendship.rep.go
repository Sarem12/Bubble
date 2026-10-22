package postgres

import (
	"bubble-api/internal/domain"
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type friendshipRepository struct {
	db *pgxpool.Pool
}

func NewFriendshipRepository(db *pgxpool.Pool) domain.FriendshipRepository {
	return &friendshipRepository{db: db}
}

func (r *friendshipRepository) Upsert(ctx context.Context, f *domain.Friendship) (*domain.Friendship, error) {
	query := `
		INSERT INTO friendships (source_user_id, target_user_id, state, is_bestfriend, ignore_in_feed, notification_state, exception_bubbles, invite_state, invite_exception_bubbles)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (source_user_id, target_user_id) DO UPDATE SET
			state = EXCLUDED.state,
			is_bestfriend = EXCLUDED.is_bestfriend,
			ignore_in_feed = EXCLUDED.ignore_in_feed,
			notification_state = EXCLUDED.notification_state,
			exception_bubbles = EXCLUDED.exception_bubbles,
			invite_state = EXCLUDED.invite_state,
			invite_exception_bubbles = EXCLUDED.invite_exception_bubbles,
			updated_at = CURRENT_TIMESTAMP
		RETURNING source_user_id, target_user_id, state, is_bestfriend, ignore_in_feed, notification_state, exception_bubbles, invite_state, invite_exception_bubbles, created_at, updated_at
	`

	err := r.db.QueryRow(ctx, query, f.SourceUserID, f.TargetUserID, f.State, f.IsBestfriend, f.IgnoreInFeed, f.NotificationState, f.ExceptionBubbles, f.InviteState, f.InviteExceptionBubbles).Scan(
		&f.SourceUserID, &f.TargetUserID, &f.State, &f.IsBestfriend, &f.IgnoreInFeed, &f.NotificationState, &f.ExceptionBubbles, &f.InviteState, &f.InviteExceptionBubbles, &f.CreatedAt, &f.UpdatedAt,
	)
	return f, err
}

func (r *friendshipRepository) Get(ctx context.Context, sourceID, targetID string) (*domain.Friendship, error) {
	query := `SELECT source_user_id, target_user_id, state, is_bestfriend, ignore_in_feed, notification_state, exception_bubbles, invite_state, invite_exception_bubbles, created_at, updated_at FROM friendships WHERE source_user_id = $1 AND target_user_id = $2`
	var f domain.Friendship
	err := r.db.QueryRow(ctx, query, sourceID, targetID).Scan(&f.SourceUserID, &f.TargetUserID, &f.State, &f.IsBestfriend, &f.IgnoreInFeed, &f.NotificationState, &f.ExceptionBubbles, &f.InviteState, &f.InviteExceptionBubbles, &f.CreatedAt, &f.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &f, nil
}

func (r *friendshipRepository) GetByState(ctx context.Context, sourceID, state string) ([]*domain.Friendship, error) {
	query := `SELECT source_user_id, target_user_id, state, is_bestfriend, ignore_in_feed, notification_state, exception_bubbles, invite_state, invite_exception_bubbles, created_at, updated_at FROM friendships WHERE source_user_id = $1 AND state = $2`
	rows, err := r.db.Query(ctx, query, sourceID, state)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var fs []*domain.Friendship
	for rows.Next() {
		var f domain.Friendship
		if err := rows.Scan(&f.SourceUserID, &f.TargetUserID, &f.State, &f.IsBestfriend, &f.IgnoreInFeed, &f.NotificationState, &f.ExceptionBubbles, &f.InviteState, &f.InviteExceptionBubbles, &f.CreatedAt, &f.UpdatedAt); err != nil {
			return nil, err
		}
		fs = append(fs, &f)
	}
	return fs, rows.Err()
}

func (r *friendshipRepository) Delete(ctx context.Context, sourceID, targetID string) error {
	query := `DELETE FROM friendships WHERE source_user_id = $1 AND target_user_id = $2`
	_, err := r.db.Exec(ctx, query, sourceID, targetID)
	return err
}

func (r *friendshipRepository) DeleteMutual(ctx context.Context, user1, user2 string) error {
	query := `DELETE FROM friendships WHERE (source_user_id = $1 AND target_user_id = $2) OR (source_user_id = $2 AND target_user_id = $1)`
	_, err := r.db.Exec(ctx, query, user1, user2)
	return err
}

func (r *friendshipRepository) UpsertMutual(ctx context.Context, f1, f2 *domain.Friendship) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	query := `
		INSERT INTO friendships (source_user_id, target_user_id, state, is_bestfriend, ignore_in_feed, notification_state, exception_bubbles, invite_state, invite_exception_bubbles)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (source_user_id, target_user_id) DO UPDATE SET
			state = EXCLUDED.state,
			is_bestfriend = EXCLUDED.is_bestfriend,
			ignore_in_feed = EXCLUDED.ignore_in_feed,
			notification_state = EXCLUDED.notification_state,
			exception_bubbles = EXCLUDED.exception_bubbles,
			invite_state = EXCLUDED.invite_state,
			invite_exception_bubbles = EXCLUDED.invite_exception_bubbles,
			updated_at = CURRENT_TIMESTAMP
	`

	_, err = tx.Exec(ctx, query, f1.SourceUserID, f1.TargetUserID, f1.State, f1.IsBestfriend, f1.IgnoreInFeed, f1.NotificationState, f1.ExceptionBubbles, f1.InviteState, f1.InviteExceptionBubbles)
	if err != nil {
		return err
	}

	_, err = tx.Exec(ctx, query, f2.SourceUserID, f2.TargetUserID, f2.State, f2.IsBestfriend, f2.IgnoreInFeed, f2.NotificationState, f2.ExceptionBubbles, f2.InviteState, f2.InviteExceptionBubbles)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func (r *friendshipRepository) BlockUserAtomic(ctx context.Context, blockF *domain.Friendship, reverseTarget, reverseSource string) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	upsertQ := `
		INSERT INTO friendships (source_user_id, target_user_id, state, is_bestfriend, ignore_in_feed, notification_state, exception_bubbles, invite_state, invite_exception_bubbles)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (source_user_id, target_user_id) DO UPDATE SET
			state = EXCLUDED.state,
			is_bestfriend = EXCLUDED.is_bestfriend,
			ignore_in_feed = EXCLUDED.ignore_in_feed,
			notification_state = EXCLUDED.notification_state,
			exception_bubbles = EXCLUDED.exception_bubbles,
			invite_state = EXCLUDED.invite_state,
			invite_exception_bubbles = EXCLUDED.invite_exception_bubbles,
			updated_at = CURRENT_TIMESTAMP
	`

	_, err = tx.Exec(ctx, upsertQ, blockF.SourceUserID, blockF.TargetUserID, blockF.State, blockF.IsBestfriend, blockF.IgnoreInFeed, blockF.NotificationState, blockF.ExceptionBubbles, blockF.InviteState, blockF.InviteExceptionBubbles)
	if err != nil {
		return err
	}

	delQ := `DELETE FROM friendships WHERE source_user_id = $1 AND target_user_id = $2`
	_, err = tx.Exec(ctx, delQ, reverseSource, reverseTarget)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}
