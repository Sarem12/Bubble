package postgres

import (
	"bubble-api/internal/domain"
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type authRepository struct {
	db *pgxpool.Pool
}

func NewAuthRepository(db *pgxpool.Pool) domain.AuthRepository {
	return &authRepository{db: db}
}

func (r *authRepository) CreateAuthWithProvider(ctx context.Context, userID, passwordHash, provider, identifier string) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var authID string
	authQuery := "INSERT INTO auth (user_id, password_hash) VALUES ($1, $2) RETURNING id"
	err = tx.QueryRow(ctx, authQuery, userID, passwordHash).Scan(&authID)
	if err != nil {
		return err
	}

	providerQuery := "INSERT INTO auth_providers (auth_id, provider, identifier) VALUES ($1, $2, $3)"
	_, err = tx.Exec(ctx, providerQuery, authID, provider, identifier)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func (r *authRepository) AddProviderToAuth(ctx context.Context, authID, provider, identifier string) error {
	query := "INSERT INTO auth_providers (auth_id, provider, identifier) VALUES ($1, $2, $3)"
	_, err := r.db.Exec(ctx, query, authID, provider, identifier)
	return err
}

func (r *authRepository) GetAuthByProvider(ctx context.Context, provider, identifier string) (*domain.Auth, error) {
	query := `
		SELECT a.id, a.user_id, a.password_hash, a.created_at
		FROM auth a
		JOIN auth_providers p ON a.id = p.auth_id
		WHERE p.provider = $1 AND p.identifier = $2
	`
	var a domain.Auth
	err := r.db.QueryRow(ctx, query, provider, identifier).Scan(&a.ID, &a.UserID, &a.PasswordHash, &a.CreatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("auth record not found")
		}
		return nil, err
	}
	return &a, nil
}

func (r *authRepository) GetAuthByUserID(ctx context.Context, userID string) (*domain.Auth, error) {
	query := "SELECT id, user_id, password_hash, created_at FROM auth WHERE user_id = $1"
	var a domain.Auth
	err := r.db.QueryRow(ctx, query, userID).Scan(&a.ID, &a.UserID, &a.PasswordHash, &a.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &a, nil
}

func (r *authRepository) UpdatePassword(ctx context.Context, authID, newPasswordHash string) error {
	query := "UPDATE auth SET password_hash = $1 WHERE id = $2"
	_, err := r.db.Exec(ctx, query, newPasswordHash, authID)
	return err
}

func (r *authRepository) CreateSession(ctx context.Context, session *domain.Session) error {
	query := `INSERT INTO sessions (user_id, device_id, device_name) VALUES ($1, $2, $3) RETURNING id, created_at, last_active_at`
	return r.db.QueryRow(ctx, query, session.UserID, session.DeviceID, session.DeviceName).Scan(&session.ID, &session.CreatedAt, &session.LastActiveAt)
}

func (r *authRepository) GetSession(ctx context.Context, sessionID string) (*domain.Session, error) {
	query := `SELECT id, user_id, device_id, device_name, created_at, last_active_at FROM sessions WHERE id = $1`
	var s domain.Session
	err := r.db.QueryRow(ctx, query, sessionID).Scan(&s.ID, &s.UserID, &s.DeviceID, &s.DeviceName, &s.CreatedAt, &s.LastActiveAt)
	return &s, err
}

func (r *authRepository) UpdateSessionLastActive(ctx context.Context, sessionID, deviceName string) error {
	query := `UPDATE sessions SET last_active_at = CURRENT_TIMESTAMP, device_name = $1 WHERE id = $2`
	_, err := r.db.Exec(ctx, query, deviceName, sessionID)
	return err
}

func (r *authRepository) DeleteSession(ctx context.Context, sessionID string) error {
	query := `DELETE FROM sessions WHERE id = $1`
	_, err := r.db.Exec(ctx, query, sessionID)
	return err
}

func (r *authRepository) GetUserSessions(ctx context.Context, userID string) ([]*domain.Session, error) {
	query := `SELECT id, user_id, device_id, device_name, created_at, last_active_at FROM sessions WHERE user_id = $1 AND COALESCE(is_revoked, FALSE) = FALSE ORDER BY last_active_at DESC`
	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	sessions := make([]*domain.Session, 0)
	for rows.Next() {
		var session domain.Session
		if err := rows.Scan(&session.ID, &session.UserID, &session.DeviceID, &session.DeviceName, &session.CreatedAt, &session.LastActiveAt); err != nil {
			return nil, err
		}
		sessions = append(sessions, &session)
	}
	return sessions, rows.Err()
}

func (r *authRepository) DeleteUserSession(ctx context.Context, userID, sessionID string) error {
	command, err := r.db.Exec(ctx, `DELETE FROM sessions WHERE user_id = $1 AND id = $2`, userID, sessionID)
	if err != nil {
		return err
	}
	if command.RowsAffected() == 0 {
		return errors.New("session not found")
	}
	return nil
}
