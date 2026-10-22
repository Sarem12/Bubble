UPDATE networks SET name = md5(random()::text) WHERE name IS NULL;
ALTER TABLE networks ALTER COLUMN name SET NOT NULL;
