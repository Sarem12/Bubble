DROP TABLE IF EXISTS reactions;

CREATE TABLE post_interactions (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    emoji_type VARCHAR(20),
    is_saved BOOLEAN NOT NULL DEFAULT false,
    last_viewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (user_id, post_id),
    CONSTRAINT valid_interaction_emoji CHECK (emoji_type IS NULL OR emoji_type IN ('heart', 'laugh', 'fire', 'thumbs_up'))
);
