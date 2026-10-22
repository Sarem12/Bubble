UPDATE friendships SET notification_state = 'EVERYCASE' WHERE notification_state = 'ON';
UPDATE friendships SET notification_state = 'NOCASE' WHERE notification_state = 'OFF';

UPDATE friendships SET invite_state = 'EVERYCASE' WHERE invite_state = 'ON';
UPDATE friendships SET invite_state = 'NOCASE' WHERE invite_state = 'OFF';

ALTER TABLE friendships DROP CONSTRAINT IF EXISTS friendships_notification_state_check;
ALTER TABLE friendships DROP CONSTRAINT IF EXISTS friendships_invite_state_check;

ALTER TABLE friendships ADD CONSTRAINT friendships_notification_state_check CHECK (notification_state IN ('AUTOMATIC', 'EVERYCASE', 'NOCASE'));
ALTER TABLE friendships ADD CONSTRAINT friendships_invite_state_check CHECK (invite_state IN ('AUTOMATIC', 'EVERYCASE', 'NOCASE'));
