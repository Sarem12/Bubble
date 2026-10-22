DO $$
BEGIN
    IF EXISTS (
        SELECT post_id
        FROM post_bubbles
        GROUP BY post_id
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Cannot rollback: posts exist with multiple bubble associations. Manual resolution required.';
    END IF;
END $$;

ALTER TABLE posts ADD COLUMN bubble_id UUID REFERENCES networks(id) ON DELETE SET NULL;

UPDATE posts p
SET bubble_id = pb.bubble_id
FROM post_bubbles pb
WHERE p.id = pb.post_id;

DROP TABLE post_bubbles;
