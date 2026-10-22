CREATE TABLE user_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    notification_state VARCHAR(20) DEFAULT 'AUTOMATIC',
    invitation_state VARCHAR(20) DEFAULT 'AUTOMATIC',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_notif_state CHECK (notification_state IN ('AUTOMATIC', 'ON', 'OFF')),
    CONSTRAINT chk_invite_state CHECK (invitation_state IN ('AUTOMATIC', 'ON', 'OFF'))
);

-- Initialize default settings for all existing users
INSERT INTO user_settings (user_id)
SELECT id FROM users;
