CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username            VARCHAR(50) UNIQUE NOT NULL,
    bio                 TEXT NOT NULL DEFAULT '',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    type                VARCHAR(10) NOT NULL DEFAULT 'PUBLIC',
    first_name          VARCHAR(100) NOT NULL DEFAULT '',
    last_name           VARCHAR(100) NOT NULL DEFAULT '',
    birthday            DATE,
    profile_picture_url TEXT NOT NULL DEFAULT '',
    last_active_at      TIMESTAMP WITH TIME ZONE,

    CONSTRAINT valid_user_type CHECK (type IN ('PRIVATE', 'PUBLIC')),
    CONSTRAINT strict_username_format CHECK (username ~ '^[a-z0-9_]+$')
);

CREATE TABLE auth (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auth_providers (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id    UUID NOT NULL REFERENCES auth(id) ON DELETE CASCADE,
    provider   VARCHAR(50) NOT NULL,
    identifier VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT valid_provider CHECK (provider IN ('email', 'phone', 'google', 'apple')),
    UNIQUE (auth_id, provider),
    UNIQUE (provider, identifier)
);

CREATE TABLE otp_codes (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider      VARCHAR(50) NOT NULL,
    identifier    VARCHAR(255) NOT NULL,
    code          VARCHAR(10) NOT NULL,
    attempts_left INT NOT NULL DEFAULT 3,
    expires_at    TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    purpose       VARCHAR(20) NOT NULL DEFAULT 'register',

    CONSTRAINT valid_provider CHECK (provider IN ('email', 'phone')),
    CONSTRAINT unique_otp_identifier UNIQUE (identifier)
);

CREATE INDEX idx_otp_identifier ON otp_codes(identifier);

CREATE TABLE sessions (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id      VARCHAR(255) NOT NULL,
    device_name    VARCHAR(255) NOT NULL,
    created_at     TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fcm_token      TEXT,
    is_revoked     BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);

CREATE TABLE user_settings (
    user_id                       UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    notification_state            VARCHAR(20) DEFAULT 'AUTOMATIC',
    invitation_state              VARCHAR(20) DEFAULT 'AUTOMATIC',
    created_at                    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at                    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    global_reaction_notifications VARCHAR(50) DEFAULT 'EVERYONE',
    global_comment_notifications  VARCHAR(50) DEFAULT 'EVERYONE',
    global_reply_notifications    VARCHAR(50) DEFAULT 'EVERYONE',
    message_notifications         VARCHAR(50) DEFAULT 'ALL_FRIENDS',
    allow_new_chats               VARCHAR(50) DEFAULT 'ALL_FRIENDS',
    top_reactions                 TEXT[] DEFAULT '{"❤️", "😂", "🔥", "👍", "😮"}'::TEXT[],

    CONSTRAINT chk_notif_state CHECK (notification_state IN ('AUTOMATIC', 'ON', 'OFF')),
    CONSTRAINT chk_invite_state CHECK (invitation_state IN ('AUTOMATIC', 'ON', 'OFF')),
    CONSTRAINT chk_global_react CHECK (global_reaction_notifications IN ('EVERYONE', 'FRIENDS', 'BUBBLE_MEMBERS', 'FRIENDS_AND_BUBBLES', 'BEST_FRIENDS', 'BEST_FRIENDS_AND_BUBBLES', 'NOBODY')),
    CONSTRAINT chk_global_comm CHECK (global_comment_notifications IN ('EVERYONE', 'FRIENDS', 'BUBBLE_MEMBERS', 'FRIENDS_AND_BUBBLES', 'BEST_FRIENDS', 'BEST_FRIENDS_AND_BUBBLES', 'NOBODY')),
    CONSTRAINT chk_global_repl CHECK (global_reply_notifications IN ('EVERYONE', 'FRIENDS', 'BUBBLE_MEMBERS', 'FRIENDS_AND_BUBBLES', 'BEST_FRIENDS', 'BEST_FRIENDS_AND_BUBBLES', 'NOBODY')),
    CONSTRAINT chk_msg_notif CHECK (message_notifications IN ('ALL_FRIENDS', 'BEST_FRIENDS', 'NOBODY')),
    CONSTRAINT chk_allow_chats CHECK (allow_new_chats IN ('ALL_FRIENDS', 'BEST_FRIENDS', 'NOBODY'))
);

CREATE TABLE networks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    type        VARCHAR(10) NOT NULL DEFAULT 'PUBLIC',
    owner_id    UUID REFERENCES users(id) ON DELETE SET NULL,
    member_key  VARCHAR(255),

    CONSTRAINT valid_network_type CHECK (type IN ('PRIVATE', 'PUBLIC', 'PERSON')),
    CONSTRAINT strict_network_name_format CHECK (name ~ '^[a-z0-9_]+$')
);

CREATE UNIQUE INDEX unique_person_network_per_user ON networks(owner_id) WHERE type = 'PERSON';

CREATE TABLE network_members (
    user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    network_id            UUID NOT NULL REFERENCES networks(id) ON DELETE CASCADE,
    role                  VARCHAR(20) DEFAULT 'member',
    notifications_enabled BOOLEAN DEFAULT TRUE,
    joined_at             TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, network_id),
    CONSTRAINT network_members_role_check CHECK (role IN ('member', 'admin', 'creator'))
);

CREATE TABLE network_invitations (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    network_id UUID REFERENCES networks(id) ON DELETE CASCADE,
    inviter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    invitee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status     VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (network_id, inviter_id, invitee_id),
    CONSTRAINT network_invitations_status_check CHECK (status IN ('pending', 'accepted', 'declined'))
);

CREATE TABLE friendships (
    source_user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    state                    VARCHAR(20) NOT NULL,
    is_bestfriend            BOOLEAN DEFAULT FALSE,
    ignore_in_feed           BOOLEAN DEFAULT FALSE,
    notification_state       VARCHAR(20) DEFAULT 'AUTOMATIC',
    exception_bubbles        UUID[] DEFAULT '{}',
    created_at               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    invite_state             VARCHAR(20) DEFAULT 'AUTOMATIC',
    invite_exception_bubbles UUID[] DEFAULT '{}',

    PRIMARY KEY (source_user_id, target_user_id),
    CONSTRAINT friendships_state_check CHECK (state IN ('friend', 'request_sent', 'request_received', 'blocked')),
    CONSTRAINT friendships_notification_state_check CHECK (notification_state IN ('AUTOMATIC', 'ON', 'OFF')),
    CONSTRAINT friendships_invite_state_check CHECK (invite_state IN ('AUTOMATIC', 'ON', 'OFF'))
);

CREATE TABLE conversations (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_users_chat UNIQUE (user1_id, user2_id),
    CONSTRAINT chk_users_order CHECK (user1_id < user2_id)
);

CREATE TABLE posts (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bubble_id              UUID REFERENCES networks(id) ON DELETE CASCADE,
    content                TEXT NOT NULL,
    created_at             TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reactions_notification VARCHAR(20) DEFAULT 'AUTOMATIC',
    comments_notification  VARCHAR(20) DEFAULT 'AUTOMATIC',
    replies_notification   VARCHAR(20) DEFAULT 'AUTOMATIC',

    CONSTRAINT chk_post_react_notif CHECK (reactions_notification IN ('AUTOMATIC', 'ON', 'OFF')),
    CONSTRAINT chk_post_comm_notif CHECK (comments_notification IN ('AUTOMATIC', 'ON', 'OFF')),
    CONSTRAINT chk_post_repl_notif CHECK (replies_notification IN ('AUTOMATIC', 'ON', 'OFF'))
);

CREATE TABLE post_media (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    media_type VARCHAR(20) NOT NULL,
    url        TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT post_media_media_type_check CHECK (media_type IN ('IMAGE', 'VIDEO'))
);

CREATE INDEX idx_post_media_post_id ON post_media(post_id);

CREATE TABLE post_interactions (
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id        UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    emoji_type     VARCHAR(20),
    is_saved       BOOLEAN NOT NULL DEFAULT FALSE,
    last_viewed_at TIMESTAMP WITH TIME ZONE,
    created_at     TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_shared      BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (user_id, post_id)
);

CREATE TABLE replies (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id         UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content         TEXT NOT NULL,
    parent_reply_id UUID REFERENCES replies(id) ON DELETE CASCADE,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reply_interactions (
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reply_id   UUID NOT NULL REFERENCES replies(id) ON DELETE CASCADE,
    emoji_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id, reply_id)
);

CREATE TABLE IF NOT EXISTS schema_migrations (
    version BIGINT PRIMARY KEY,
    dirty   BOOLEAN NOT NULL
);

INSERT INTO schema_migrations (version, dirty)
VALUES (33, FALSE)
ON CONFLICT (version) DO UPDATE SET dirty = EXCLUDED.dirty;
