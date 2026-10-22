ALTER TABLE posts ADD COLUMN IF NOT EXISTS bubble_id UUID REFERENCES networks(id) ON DELETE CASCADE;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables 
        WHERE table_name = 'post_bubbles'
    ) THEN
        UPDATE posts p
        SET bubble_id = pb.bubble_id
        FROM (
            SELECT DISTINCT ON (post_id) post_id, bubble_id
            FROM post_bubbles
            ORDER BY post_id, bubble_id
        ) pb
        WHERE p.id = pb.post_id;

        DROP TABLE post_bubbles;
    END IF;
END $$;
