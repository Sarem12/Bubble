package postgres

import (
	"bubble-api/internal/domain"
	"context"
	"database/sql"
	"errors"

	"github.com/jackc/pgx/v5/pgxpool"
)

type bubbleRepository struct {
	db *pgxpool.Pool
}

func NewBubbleRepository(db *pgxpool.Pool) domain.BubbleRepository {
	return &bubbleRepository{db: db}
}

func (r *bubbleRepository) Create(ctx context.Context, bubble *domain.Bubble) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	query := `INSERT INTO networks (name, description, type, owner_id, member_key) VALUES (NULLIF($1, ''), $2, COALESCE(NULLIF($3, ''), 'PUBLIC'), $4, $5) RETURNING id, type, created_at`
	err = tx.QueryRow(ctx, query, bubble.Name, bubble.Description, bubble.Type, bubble.OwnerID, bubble.MemberKey).Scan(&bubble.ID, &bubble.Type, &bubble.CreatedAt)
	if err != nil {
		return err
	}

	if bubble.OwnerID != nil {
		q2 := `INSERT INTO network_members (user_id, network_id, role) VALUES ($1, $2, 'creator')`
		_, err = tx.Exec(ctx, q2, bubble.OwnerID, bubble.ID)
		if err != nil {
			return err
		}
	}
	return tx.Commit(ctx)
}

func (r *bubbleRepository) GetByID(ctx context.Context, id string) (*domain.Bubble, error) {
	query := `SELECT id, COALESCE(name, ''), description, type, owner_id, member_key, created_at FROM networks WHERE id = $1`
	var b domain.Bubble
	err := r.db.QueryRow(ctx, query, id).Scan(&b.ID, &b.Name, &b.Description, &b.Type, &b.OwnerID, &b.MemberKey, &b.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &b, nil
}

func (r *bubbleRepository) GetByName(ctx context.Context, name string) (*domain.Bubble, error) {
	query := `SELECT id, COALESCE(name, ''), description, type, owner_id, member_key, created_at FROM networks WHERE name = $1`
	var b domain.Bubble
	err := r.db.QueryRow(ctx, query, name).Scan(&b.ID, &b.Name, &b.Description, &b.Type, &b.OwnerID, &b.MemberKey, &b.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &b, nil
}

func (r *bubbleRepository) GetBubbles(ctx context.Context, nameFilter string, sortBy string, limit int) ([]*domain.Bubble, error) {
	var query string
	nameFilter = "%" + nameFilter + "%"

	if sortBy == "popular" {
		query = `
		SELECT n.id, COALESCE(n.name, ''), n.description, n.type, n.owner_id, n.member_key, n.created_at
		FROM networks n
		LEFT JOIN network_members m ON n.id = m.network_id
		WHERE n.name ILIKE $1 AND n.type = 'PUBLIC'
		GROUP BY n.id
		ORDER BY COUNT(m.user_id) DESC, n.created_at DESC
		LIMIT $2
		`
	} else {
		query = `
		SELECT id, COALESCE(name, ''), description, type, owner_id, member_key, created_at 
		FROM networks 
		WHERE name ILIKE $1 AND type = 'PUBLIC'
		ORDER BY created_at DESC 
		LIMIT $2
		`
	}

	rows, err := r.db.Query(ctx, query, nameFilter, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var bubbles []*domain.Bubble
	for rows.Next() {
		var b domain.Bubble
		if err := rows.Scan(&b.ID, &b.Name, &b.Description, &b.Type, &b.OwnerID, &b.MemberKey, &b.CreatedAt); err != nil {
			return nil, err
		}
		bubbles = append(bubbles, &b)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if bubbles == nil {
		bubbles = []*domain.Bubble{}
	}
	return bubbles, nil
}

func (r *bubbleRepository) Update(ctx context.Context, bubble *domain.Bubble) error {
	query := `UPDATE networks SET name = $1, description = $2 WHERE id = $3`
	result, err := r.db.Exec(ctx, query, bubble.Name, bubble.Description, bubble.ID)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return errors.New("bubble not found")
	}
	return nil
}

func (r *bubbleRepository) Delete(ctx context.Context, id string) error {
	query := `DELETE FROM networks WHERE id = $1`
	result, err := r.db.Exec(ctx, query, id)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return errors.New("bubble not found")
	}
	return nil
}

func (r *bubbleRepository) Join(ctx context.Context, member *domain.BubbleMember) error {
	query := `INSERT INTO network_members (user_id, network_id, role) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING`
	_, err := r.db.Exec(ctx, query, member.UserID, member.BubbleID, member.Role)
	return err
}

func (r *bubbleRepository) Leave(ctx context.Context, userID, bubbleID string) error {
	query := `DELETE FROM network_members WHERE user_id = $1 AND network_id = $2`
	_, err := r.db.Exec(ctx, query, userID, bubbleID)
	return err
}

func (r *bubbleRepository) GetMembers(ctx context.Context, bubbleID string) ([]*domain.BubbleMember, error) {
	query := `SELECT user_id, network_id, role, notifications_enabled, joined_at FROM network_members WHERE network_id = $1`
	rows, err := r.db.Query(ctx, query, bubbleID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var members []*domain.BubbleMember
	for rows.Next() {
		var m domain.BubbleMember
		if err := rows.Scan(&m.UserID, &m.BubbleID, &m.Role, &m.NotificationsEnabled, &m.JoinedAt); err != nil {
			return nil, err
		}
		members = append(members, &m)
	}
	return members, rows.Err()
}

func (r *bubbleRepository) CreateInvitation(ctx context.Context, invite *domain.BubbleInvitation) error {
	query := `INSERT INTO network_invitations (network_id, inviter_id, invitee_id) VALUES ($1, $2, $3) RETURNING id, status, created_at`
	return r.db.QueryRow(ctx, query, invite.BubbleID, invite.InviterID, invite.InviteeID).Scan(&invite.ID, &invite.Status, &invite.CreatedAt)
}
func (r *bubbleRepository) GetInvitation(ctx context.Context, inviteID string) (*domain.BubbleInvitation, error) {
	query := `SELECT id, network_id, inviter_id, invitee_id, status, created_at FROM network_invitations WHERE id = $1`
	var i domain.BubbleInvitation
	err := r.db.QueryRow(ctx, query, inviteID).Scan(&i.ID, &i.BubbleID, &i.InviterID, &i.InviteeID, &i.Status, &i.CreatedAt)
	return &i, err
}
func (r *bubbleRepository) UpdateInvitationStatus(ctx context.Context, inviteID, status string) error {
	query := `UPDATE network_invitations SET status = $1 WHERE id = $2`
	_, err := r.db.Exec(ctx, query, status, inviteID)
	return err
}

func (r *bubbleRepository) AcceptInvitationAndJoin(ctx context.Context, inviteID, userID, bubbleID string) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	q1 := `UPDATE network_invitations
	       SET status = 'accepted'
	       WHERE id = $1 AND invitee_id = $2 AND network_id = $3 AND status = 'pending'`
	res, err := tx.Exec(ctx, q1, inviteID, userID, bubbleID)
	if err != nil {
		return err
	}
	if res.RowsAffected() == 0 {
		return errors.New("invitation not found or not pending")
	}
	q2 := `INSERT INTO network_members (user_id, network_id, role) VALUES ($1, $2, 'member') ON CONFLICT DO NOTHING`
	if _, err := tx.Exec(ctx, q2, userID, bubbleID); err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func (r *bubbleRepository) CheckMembership(ctx context.Context, userID, bubbleID string) (bool, error) {
	var count int
	query := "SELECT COUNT(*) FROM network_members WHERE user_id = $1 AND network_id = $2"
	err := r.db.QueryRow(ctx, query, userID, bubbleID).Scan(&count)
	return count > 0, err
}

func (r *bubbleRepository) GetPersonBubbleByOwnerID(ctx context.Context, ownerID string) (*domain.Bubble, error) {
	query := `SELECT id, COALESCE(name, ''), description, type, owner_id, member_key, created_at FROM networks WHERE owner_id = $1 AND type = 'PERSON' LIMIT 1`
	var b domain.Bubble
	err := r.db.QueryRow(ctx, query, ownerID).Scan(&b.ID, &b.Name, &b.Description, &b.Type, &b.OwnerID, &b.MemberKey, &b.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &b, nil
}

func (r *bubbleRepository) GetUserBubbles(ctx context.Context, userID string, isSelf bool) ([]*domain.Bubble, error) {
	query := `
		SELECT b.id, COALESCE(b.name, ''), COALESCE(b.description, ''), b.type, b.owner_id, b.created_at,
		       CASE WHEN $2 THEN COALESCE(nm.notifications_enabled, true) ELSE NULL END
		FROM networks b
		LEFT JOIN network_members nm ON nm.network_id = b.id AND nm.user_id = $1
		WHERE (b.type = 'PUBLIC' OR (b.type = 'PRIVATE' AND $2 = true))
		  AND (
		    b.owner_id = $1
		    OR EXISTS (
		      SELECT 1 FROM network_members nm
		      WHERE nm.network_id = b.id AND nm.user_id = $1
		    )
		  )
		ORDER BY b.created_at DESC
	`
	rows, err := r.db.Query(ctx, query, userID, isSelf)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var bubbles []*domain.Bubble
	for rows.Next() {
		var b domain.Bubble
		var notifications sql.NullBool
		if err := rows.Scan(&b.ID, &b.Name, &b.Description, &b.Type, &b.OwnerID, &b.CreatedAt, &notifications); err != nil {
			return nil, err
		}
		if notifications.Valid {
			b.NotificationsEnabled = &notifications.Bool
		}
		bubbles = append(bubbles, &b)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if bubbles == nil {
		bubbles = []*domain.Bubble{}
	}
	return bubbles, nil
}

func (r *bubbleRepository) UpdateMemberNotifications(ctx context.Context, userID, bubbleID string, enabled bool) error {
	result, err := r.db.Exec(ctx, `UPDATE network_members SET notifications_enabled = $1 WHERE user_id = $2 AND network_id = $3`, enabled, userID, bubbleID)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return errors.New("bubble membership not found")
	}
	return nil
}
