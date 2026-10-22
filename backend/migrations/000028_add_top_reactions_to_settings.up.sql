ALTER TABLE user_settings ADD COLUMN top_reactions TEXT[] DEFAULT '{"❤️", "😂", "🔥", "👍", "😮"}'::TEXT[];
