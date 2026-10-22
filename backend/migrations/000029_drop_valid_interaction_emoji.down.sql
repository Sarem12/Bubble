ALTER TABLE post_interactions ADD CONSTRAINT valid_interaction_emoji CHECK (emoji_type IS NULL OR emoji_type IN ('heart', 'laugh', 'fire', 'thumbs_up'));
