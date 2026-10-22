package postgres

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type otpRepository struct {
	db *pgxpool.Pool
}

func NewOTPRepository(db *pgxpool.Pool) domain.OTPRepository {
	return &otpRepository{db: db}
}

func (r *otpRepository) CreateOTP(ctx context.Context, provider, identifier, purpose, code string, expiresAt time.Time) error {
	// First, explicitly delete any existing OTP for this identifier!
	deleteQuery := "DELETE FROM otp_codes WHERE identifier = $1"
	_, _ = r.db.Exec(ctx, deleteQuery, identifier)

	query := "INSERT INTO otp_codes (provider, identifier, purpose, code, expires_at) VALUES ($1, $2, $3, $4, $5)"
	_, err := r.db.Exec(ctx, query, provider, identifier, purpose, code, expiresAt)
	return err
}

func (r *otpRepository) GetOTPByIdentifier(ctx context.Context, identifier string) (*domain.OTPCode, error) {
	query := "SELECT id, provider, identifier, purpose, code, attempts_left, expires_at, created_at FROM otp_codes WHERE identifier = $1"
	var otp domain.OTPCode
	err := r.db.QueryRow(ctx, query, identifier).Scan(&otp.ID, &otp.Provider, &otp.Identifier, &otp.Purpose, &otp.Code, &otp.AttemptsLeft, &otp.ExpiresAt, &otp.CreatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("no otp found")
		}
		return nil, err
	}
	return &otp, nil
}

func (r *otpRepository) DecrementAttempts(ctx context.Context, id string) error {
	query := `UPDATE otp_codes SET attempts_left = attempts_left - 1 WHERE id = $1 AND attempts_left > 0`
	tag, err := r.db.Exec(ctx, query, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return errors.New("no attempts left or code not found")
	}
	return nil
}

func (r *otpRepository) DeleteOTP(ctx context.Context, id string) error {
	query := `DELETE FROM otp_codes WHERE id = $1`
	_, err := r.db.Exec(ctx, query, id)
	return err
}

func (r *otpRepository) CountRecentOTPs(ctx context.Context, identifier string, since time.Time) (int, error) {
	query := `SELECT COUNT(*) FROM otp_codes WHERE identifier = $1 AND created_at > $2`
	var count int
	err := r.db.QueryRow(ctx, query, identifier, since).Scan(&count)
	return count, err
}

func (r *otpRepository) DeleteExpiredOTPs(ctx context.Context) error {
	query := `DELETE FROM otp_codes WHERE expires_at < NOW()`
	_, err := r.db.Exec(ctx, query)
	return err
}
