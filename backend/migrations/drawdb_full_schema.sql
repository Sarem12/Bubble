CREATE TABLE users (
    id                  UUID PRIMARY KEY,
    username            VARCHAR(50) UNIQUE NOT NULL,
    bio                 TEXT NOT NULL DEFAULT '',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    type                VARCHAR(10) NOT NULL DEFAULT 'PUBLIC',
    first_name          VARCHAR(100) NOT NULL DEFAULT '',
    last_name           VARCHAR(100) NOT NULL DEFAULT '',
    birthday            DATE,
    profile_picture_url TEXT NOT NULL DEFAULT '',
    last_active_at      TIMESTAMP WITH TIME ZONE
);

CREATE TABLE auth (
    id            UUID PRIMARY KEY,
    user_id       UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auth_providers (
    id         UUID PRIMARY KEY,
    auth_id    UUID NOT NULL REFERENCES auth(id) ON DELETE CASCADE,
    provider   VARCHAR(50) NOT NULL,
    identifier VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (auth_id, provider),
    UNIQUE (provider, identifier)
);

CREATE TABLE otp_codes (
    id            UUID PRIMARY KEY,
    provider      VARCHAR(50) NOT NULL,
    identifier    VARCHAR(255) NOT NULL,
    code          VARCHAR(10) NOT NULL,
    attempts_left INT NOT NULL DEFAULT 3,
    expires_at    TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    purpose       VARCHAR(20) NOT NULL DEFAULT 'register',
    UNIQUE (identifier)
);

CREATE TABLE sessions (
    id             UUID PRIMARY KEY,
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id      VARCHAR(255) NOT NULL,
    device_name    VARCHAR(255) NOT NULL,
    created_at     TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fcm_token      TEXT,
    is_revoked     BOOLEAN DEFAULT FALSE
);

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
    top_reactions                 TEXT
);

CREATE TABLE networks (
    id          UUID PRIMARY KEY,
    name        VARCHAR(100) UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    type        VARCHAR(10) NOT NULL DEFAULT 'PUBLIC',
    owner_id    UUID REFERENCES users(id) ON DELETE SET NULL,
    member_key  VARCHAR(255)
);

CREATE TABLE network_members (
    user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    network_id            UUID NOT NULL REFERENCES networks(id) ON DELETE CASCADE,
    role                  VARCHAR(20) DEFAULT 'member',
    notifications_enabled BOOLEAN DEFAULT TRUE,
    joined_at             TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, network_id)
);

CREATE TABLE network_invitations (
    id         UUID PRIMARY KEY,
    network_id UUID REFERENCES networks(id) ON DELETE CASCADE,
    inviter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    invitee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status     VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (network_id, inviter_id, invitee_id)
);

CREATE TABLE friendships (
    source_user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    state                    VARCHAR(20) NOT NULL,
    is_bestfriend            BOOLEAN DEFAULT FALSE,
    ignore_in_feed           BOOLEAN DEFAULT FALSE,
    notification_state       VARCHAR(20) DEFAULT 'AUTOMATIC',
    exception_bubbles        TEXT,
    created_at               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    invite_state             VARCHAR(20) DEFAULT 'AUTOMATIC',
    invite_exception_bubbles TEXT,
    PRIMARY KEY (source_user_id, target_user_id)
);

CREATE TABLE conversations (
    id         UUID PRIMARY KEY,
    user1_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user1_id, user2_id)
);

CREATE TABLE posts (
    id                     UUID PRIMARY KEY,
    user_id                UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    bubble_id              UUID REFERENCES networks(id) ON DELETE CASCADE,
    content                TEXT NOT NULL,
    created_at             TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reactions_notification VARCHAR(20) DEFAULT 'AUTOMATIC',
    comments_notification  VARCHAR(20) DEFAULT 'AUTOMATIC',
    replies_notification   VARCHAR(20) DEFAULT 'AUTOMATIC'
);

CREATE TABLE post_media (
    id         UUID PRIMARY KEY,
    post_id    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    media_type VARCHAR(20) NOT NULL,
    url        TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

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
    id              UUID PRIMARY KEY,
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

CREATE TABLE mongo_conversations (
    id           VARCHAR(64) PRIMARY KEY REFERENCES conversations(id) ON DELETE CASCADE,
    participants TEXT,
    last_message TEXT,
    updated_at   TIMESTAMP WITH TIME ZONE
);

CREATE TABLE mongo_messages (
    id              VARCHAR(64) PRIMARY KEY,
    conversation_id VARCHAR(64) NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    topic           VARCHAR(100),
    content         TEXT NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE,
    read_at         TIMESTAMP WITH TIME ZONE
);

CREATE TABLE mongo_message_reactions (
    message_id VARCHAR(64) NOT NULL REFERENCES mongo_messages(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji      VARCHAR(20) NOT NULL,
    PRIMARY KEY (message_id, user_id)
);
