-- Update existing NULLs to empty strings
UPDATE users SET bio = '' WHERE bio IS NULL;
UPDATE users SET first_name = '' WHERE first_name IS NULL;
UPDATE users SET last_name = '' WHERE last_name IS NULL;
UPDATE networks SET description = '' WHERE description IS NULL;
UPDATE auth_identities SET password_hash = '' WHERE password_hash IS NULL;

-- Enforce NOT NULL and set DEFAULT to empty string
ALTER TABLE users 
    ALTER COLUMN bio SET DEFAULT '',
    ALTER COLUMN bio SET NOT NULL,
    ALTER COLUMN first_name SET DEFAULT '',
    ALTER COLUMN first_name SET NOT NULL,
    ALTER COLUMN last_name SET DEFAULT '',
    ALTER COLUMN last_name SET NOT NULL;

ALTER TABLE networks 
    ALTER COLUMN description SET DEFAULT '',
    ALTER COLUMN description SET NOT NULL;

ALTER TABLE auth_identities 
    ALTER COLUMN password_hash SET DEFAULT '',
    ALTER COLUMN password_hash SET NOT NULL;
