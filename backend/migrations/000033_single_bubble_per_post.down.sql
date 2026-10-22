CREATE TABLE IF NOT EXISTS post_bubbles (
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    bubble_id UUID REFERENCES networks(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, bubble_id)
);

CREATE INDEX IF NOT EXISTS idx_post_bubbles_reverse ON post_bubbles(bubble_id, post_id);

INSERT INTO post_bubbles (post_id, bubble_id)
SELECT id, bubble_id FROM posts WHERE bubble_id IS NOT NULL
ON CONFLICT DO NOTHING;

ALTER TABLE posts DROP COLUMN IF EXISTS bubble_id;
