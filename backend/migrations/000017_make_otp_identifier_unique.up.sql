-- Remove duplicates before applying constraint
DELETE FROM otp_codes
WHERE id NOT IN (
    SELECT id
    FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY identifier ORDER BY created_at DESC) as rn
        FROM otp_codes
    ) t
    WHERE t.rn = 1
);

-- Force the database to guarantee identifier uniqueness
ALTER TABLE otp_codes ADD CONSTRAINT unique_otp_identifier UNIQUE (identifier);
