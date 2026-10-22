-- Add the birthday column (DATE type perfectly holds Year/Month/Day without timezone issues)
ALTER TABLE users ADD COLUMN birthday DATE;
