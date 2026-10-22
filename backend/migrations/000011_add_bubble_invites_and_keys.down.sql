DROP TABLE IF EXISTS network_invitations;
ALTER TABLE friendships DROP COLUMN IF EXISTS invite_state, DROP COLUMN IF EXISTS invite_exception_bubbles;
ALTER TABLE networks DROP COLUMN IF EXISTS member_key;
