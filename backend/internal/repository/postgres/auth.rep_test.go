package postgres

import (
	"context"
	"os"
	"testing"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
)

func TestAuthRepository(t *testing.T) {
	dbURL := os.Getenv("TEST_DB_URL")
	if dbURL == "" {
		t.Skip("TEST_DB_URL not set")
	}
	pool, err := pgxpool.New(context.Background(), dbURL)
	assert.NoError(t, err)
	defer pool.Close()
	repo := NewAuthRepository(pool)
	assert.NotNil(t, repo)
}
