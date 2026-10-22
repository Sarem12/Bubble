-- Update data to new formats
UPDATE friendships SET notification_state = 'ON' WHERE notification_state = 'EVERYCASE';
UPDATE friendships SET notification_state = 'OFF' WHERE notification_state = 'NOCASE';

UPDATE friendships SET invite_state = 'ON' WHERE invite_state = 'EVERYCASE';
UPDATE friendships SET invite_state = 'OFF' WHERE invite_state = 'NOCASE';

-- Drop old constraints
ALTER TABLE friendships DROP CONSTRAINT IF EXISTS friendships_notification_state_check;
ALTER TABLE friendships DROP CONSTRAINT IF EXISTS friendships_invite_state_check;

-- Add new constraints
ALTER TABLE friendships ADD CONSTRAINT friendships_notification_state_check CHECK (notification_state IN ('AUTOMATIC', 'ON', 'OFF'));
ALTER TABLE friendships ADD CONSTRAINT friendships_invite_state_check CHECK (invite_state IN ('AUTOMATIC', 'ON', 'OFF'));
