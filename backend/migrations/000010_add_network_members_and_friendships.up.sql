-- 1. Bubble Membership (network_members)
ALTER TABLE networks ADD COLUMN owner_id UUID REFERENCES users(id) ON DELETE SET NULL;

CREATE TABLE network_members (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    network_id UUID REFERENCES networks(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('member', 'admin', 'creator')),
    notifications_enabled BOOLEAN DEFAULT true,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, network_id)
);

-- 2. Friendships (Person to Person)
CREATE TABLE friendships (
    source_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    target_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    state VARCHAR(20) NOT NULL CHECK (state IN ('friend', 'request_sent', 'request_received', 'blocked')),
    
    -- Granular Settings (Based on our discussion)
    is_bestfriend BOOLEAN DEFAULT false,
    ignore_in_feed BOOLEAN DEFAULT false,
    notification_state VARCHAR(20) DEFAULT 'AUTOMATIC' CHECK (notification_state IN ('EVERYCASE', 'NOCASE', 'AUTOMATIC')),
    exception_bubbles UUID[] DEFAULT '{}', -- List of bubble IDs that bypass the notification_state
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (source_user_id, target_user_id)
);
