ALTER TABLE posts
DROP COLUMN IF EXISTS reactions_notification,
DROP COLUMN IF EXISTS comments_notification,
DROP COLUMN IF EXISTS replies_notification;

ALTER TABLE user_settings
DROP COLUMN IF EXISTS global_reaction_notifications,
DROP COLUMN IF EXISTS global_comment_notifications,
DROP COLUMN IF EXISTS global_reply_notifications,
DROP COLUMN IF EXISTS message_notifications,
DROP COLUMN IF EXISTS allow_new_chats;
