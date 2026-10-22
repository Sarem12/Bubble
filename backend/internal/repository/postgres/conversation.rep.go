package postgres

import (
	"context"
	"bubble-api/internal/domain"
	"github.com/jackc/pgx/v5/pgxpool"
)

type conversationRepository struct {
	db *pgxpool.Pool
}

func NewConversationRepository(db *pgxpool.Pool) domain.ConversationRepository {
	return &conversationRepository{db: db}
}

func (r *conversationRepository) CreateOrGet(ctx context.Context, u1, u2 string) (*domain.Conversation, error) {
	if u1 > u2 {
		u1, u2 = u2, u1
	}

	query := `
		INSERT INTO conversations (user1_id, user2_id)
		VALUES ($1, $2)
		ON CONFLICT (user1_id, user2_id) DO UPDATE SET updated_at = CURRENT_TIMESTAMP
		RETURNING id, user1_id, user2_id, created_at, updated_at
	`
	var c domain.Conversation
	err := r.db.QueryRow(ctx, query, u1, u2).Scan(&c.ID, &c.User1ID, &c.User2ID, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

func (r *conversationRepository) GetConversationsForUser(ctx context.Context, userID string) ([]*domain.Conversation, error) {
	query := `
		SELECT id, user1_id, user2_id, created_at, updated_at
		FROM conversations
		WHERE user1_id = $1 OR user2_id = $1
		ORDER BY updated_at DESC
	`
	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var convs []*domain.Conversation
	for rows.Next() {
		var c domain.Conversation
		err := rows.Scan(&c.ID, &c.User1ID, &c.User2ID, &c.CreatedAt, &c.UpdatedAt)
		if err != nil {
			return nil, err
		}
		convs = append(convs, &c)
	}
	return convs, nil
}
