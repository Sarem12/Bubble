package postgres

import (
	"context"
	"os"
	"testing"
	"bubble-api/internal/domain"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
)

func TestBubbleRepository(t *testing.T) {
	dbURL := os.Getenv("TEST_DB_URL")
	if dbURL == "" {
		t.Skip("TEST_DB_URL not set")
	}
	pool, err := pgxpool.New(context.Background(), dbURL)
	assert.NoError(t, err)
	defer pool.Close()
	repo := NewBubbleRepository(pool)

	bubble := &domain.Bubble{
		Name:		"testbubble",
		Description:	"test desc",
	}
	err = repo.Create(context.Background(), bubble)
	assert.NoError(t, err)

	err = repo.Delete(context.Background(), bubble.ID)
	assert.NoError(t, err)
}
