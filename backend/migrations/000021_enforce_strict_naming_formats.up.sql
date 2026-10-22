-- 1. Fix existing usernames
UPDATE users 
SET username = regexp_replace(lower(username), '[^a-z0-9_]', '_', 'g') 
WHERE username !~ '^[a-z0-9_]+$';

-- 2. Enforce username constraint
ALTER TABLE users 
ADD CONSTRAINT strict_username_format 
CHECK (username ~ '^[a-z0-9_]+$');

-- 3. Fix existing network (bubble) names
UPDATE networks 
SET name = regexp_replace(lower(name), '[^a-z0-9_]', '_', 'g') 
WHERE name !~ '^[a-z0-9_]+$';

-- 4. Enforce network name constraint
ALTER TABLE networks 
ADD CONSTRAINT strict_network_name_format 
CHECK (name ~ '^[a-z0-9_]+$');
