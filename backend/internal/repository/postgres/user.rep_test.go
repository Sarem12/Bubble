package postgres

import (
	"context"
	"os"
	"testing"
	"bubble-api/internal/domain"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
)

func setupTestDB(t *testing.T) *pgxpool.Pool {
	dbURL := os.Getenv("TEST_DB_URL")
	if dbURL == "" {
		t.Skip("TEST_DB_URL not set, skipping repository test")
	}
	pool, err := pgxpool.New(context.Background(), dbURL)
	assert.NoError(t, err)
	return pool
}

func TestUserRepository(t *testing.T) {
	pool := setupTestDB(t)
	defer pool.Close()
	repo := NewUserRepository(pool)

	user := &domain.User{
		Username: "testuser",
		Bio:      "test bio",
	}
	err := repo.Create(context.Background(), user)
	assert.NoError(t, err)
	assert.NotEmpty(t, user.ID)

	err = repo.Delete(context.Background(), user.ID)
	assert.NoError(t, err)
}
