DROP TABLE IF EXISTS post_interactions;

CREATE TABLE reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    emoji_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_emoji CHECK (emoji_type IN ('heart', 'laugh', 'fire', 'thumbs_up')),
    UNIQUE(user_id, post_id, emoji_type)
);
