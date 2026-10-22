CREATE TABLE post_bubbles (
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    bubble_id UUID REFERENCES networks(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, bubble_id)
);

CREATE INDEX idx_post_bubbles_reverse ON post_bubbles(bubble_id, post_id);

-- Migrate existing data
INSERT INTO post_bubbles (post_id, bubble_id)
SELECT id, bubble_id FROM posts WHERE bubble_id IS NOT NULL;

-- Drop the old column
ALTER TABLE posts DROP COLUMN bubble_id;
