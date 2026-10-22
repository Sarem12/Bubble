package postgres

import (
	"bubble-api/internal/domain"
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type userRepository struct {
	db *pgxpool.Pool
}

func NewUserRepository(db *pgxpool.Pool) domain.UserRepository {
	return &userRepository{
		db: db,
	}
}

// NewPersonRepository is an alias constructor for backwards compatibility.
func NewPersonRepository(db *pgxpool.Pool) domain.UserRepository {
	return NewUserRepository(db)
}

func (r *userRepository) Create(ctx context.Context, user *domain.User) error {
	query := `
		INSERT INTO users (username, first_name, last_name, bio, profile_picture_url, birthday) 
		VALUES ($1, $2, $3, $4, $5, $6) 
		RETURNING id, created_at`
	err := r.db.QueryRow(ctx, query, user.Username, user.FirstName, user.LastName, user.Bio, user.ProfilePictureURL, user.Birthday).Scan(&user.ID, &user.CreatedAt)
	if err != nil {
		return err
	}

	return nil
}

func (r *userRepository) GetByID(ctx context.Context, id string) (*domain.User, error) {
	query := `SELECT id, username, type, first_name, last_name, bio, profile_picture_url, created_at, birthday, last_active_at FROM users WHERE id = $1`

	var u domain.User
	err := r.db.QueryRow(ctx, query, id).Scan(&u.ID, &u.Username, &u.Type, &u.FirstName, &u.LastName, &u.Bio, &u.ProfilePictureURL, &u.CreatedAt, &u.Birthday, &u.LastActiveAt)
	if err != nil {
		return nil, err
	}

	return &u, nil
}

func (r *userRepository) GetAll(ctx context.Context) ([]*domain.User, error) {
	query := `SELECT id, username, type, first_name, last_name, bio, profile_picture_url, created_at, birthday, last_active_at FROM users`
	rows, err := r.db.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []*domain.User
	for rows.Next() {
		var u domain.User
		if err := rows.Scan(&u.ID, &u.Username, &u.Type, &u.FirstName, &u.LastName, &u.Bio, &u.ProfilePictureURL, &u.CreatedAt, &u.Birthday, &u.LastActiveAt); err != nil {
			return nil, err
		}
		users = append(users, &u)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return users, nil
}

func (r *userRepository) Update(ctx context.Context, u *domain.User) error {
	query := `UPDATE users SET username = $1, type = $2, first_name = $3, last_name = $4, bio = $5, profile_picture_url = $6, birthday = $7 WHERE id = $8`
	tag, err := r.db.Exec(ctx, query, u.Username, u.Type, u.FirstName, u.LastName, u.Bio, u.ProfilePictureURL, u.Birthday, u.ID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return errors.New("user not found")
	}
	return nil
}

func (r *userRepository) Delete(ctx context.Context, id string) error {
	query := `DELETE FROM users WHERE id = $1`
	tag, err := r.db.Exec(ctx, query, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return errors.New("user not found")
	}
	return nil
}

func (r *userRepository) GetByUsername(ctx context.Context, username string) (*domain.User, error) {
	query := `SELECT id, username, type, first_name, last_name, bio, profile_picture_url, created_at, birthday, last_active_at FROM users WHERE username = $1`
	var u domain.User
	err := r.db.QueryRow(ctx, query, username).Scan(&u.ID, &u.Username, &u.Type, &u.FirstName, &u.LastName, &u.Bio, &u.ProfilePictureURL, &u.CreatedAt, &u.Birthday, &u.LastActiveAt)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *userRepository) UpdateLastActive(ctx context.Context, id string, lastActive time.Time) error {
	query := `UPDATE users SET last_active_at = $1 WHERE id = $2`
	_, err := r.db.Exec(ctx, query, lastActive, id)
	return err
}

func (r *userRepository) UpdateProfilePicture(ctx context.Context, id, pictureURL string) error {
	query := `UPDATE users SET profile_picture_url = $1 WHERE id = $2`
	tag, err := r.db.Exec(ctx, query, pictureURL, id)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return errors.New("user not found")
	}
	return nil
}

func (r *userRepository) GetSettings(ctx context.Context, userID string) (*domain.UserSettings, error) {
	query := `SELECT user_id, notification_state, invitation_state, global_reaction_notifications, global_comment_notifications, global_reply_notifications, message_notifications, allow_new_chats, COALESCE(top_reactions, '{}') FROM user_settings WHERE user_id = $1`
	var us domain.UserSettings
	err := r.db.QueryRow(ctx, query, userID).Scan(
		&us.UserID,
		&us.NotificationState,
		&us.InvitationState,
		&us.GlobalReactionNotifications,
		&us.GlobalCommentNotifications,
		&us.GlobalReplyNotifications,
		&us.MessageNotifications,
		&us.AllowNewChats,
		&us.TopReactions,
	)
	if err != nil {
		return nil, err
	}
	return &us, nil
}

func (r *userRepository) UpdateSettings(ctx context.Context, userID string, params domain.UpdateSettingsParams) (*domain.UserSettings, error) {
	query := `UPDATE user_settings 
	          SET notification_state = COALESCE($1, notification_state), 
	              invitation_state = COALESCE($2, invitation_state),
	              global_reaction_notifications = COALESCE($3, global_reaction_notifications),
	              global_comment_notifications = COALESCE($4, global_comment_notifications),
	              global_reply_notifications = COALESCE($5, global_reply_notifications),
	              message_notifications = COALESCE($6, message_notifications),
	              allow_new_chats = COALESCE($7, allow_new_chats),
	              top_reactions = COALESCE($8, top_reactions)
	          WHERE user_id = $9
	          RETURNING user_id, notification_state, invitation_state, global_reaction_notifications, global_comment_notifications, global_reply_notifications, message_notifications, allow_new_chats, top_reactions`

	var us domain.UserSettings
	err := r.db.QueryRow(ctx, query,
		params.NotificationState,
		params.InvitationState,
		params.GlobalReactionNotifications,
		params.GlobalCommentNotifications,
		params.GlobalReplyNotifications,
		params.MessageNotifications,
		params.AllowNewChats,
		params.TopReactions,
		userID).Scan(
		&us.UserID,
		&us.NotificationState,
		&us.InvitationState,
		&us.GlobalReactionNotifications,
		&us.GlobalCommentNotifications,
		&us.GlobalReplyNotifications,
		&us.MessageNotifications,
		&us.AllowNewChats,
		&us.TopReactions,
	)

	if err != nil {
		return nil, err
	}
	return &us, nil
}
