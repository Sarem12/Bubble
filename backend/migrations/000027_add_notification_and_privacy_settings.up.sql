ALTER TABLE posts
ADD COLUMN reactions_notification VARCHAR(20) DEFAULT 'AUTOMATIC',
ADD COLUMN comments_notification VARCHAR(20) DEFAULT 'AUTOMATIC',
ADD COLUMN replies_notification VARCHAR(20) DEFAULT 'AUTOMATIC',
ADD CONSTRAINT chk_post_react_notif CHECK (reactions_notification IN ('AUTOMATIC', 'ON', 'OFF')),
ADD CONSTRAINT chk_post_comm_notif CHECK (comments_notification IN ('AUTOMATIC', 'ON', 'OFF')),
ADD CONSTRAINT chk_post_repl_notif CHECK (replies_notification IN ('AUTOMATIC', 'ON', 'OFF'));

ALTER TABLE user_settings
ADD COLUMN global_reaction_notifications VARCHAR(50) DEFAULT 'EVERYONE',
ADD COLUMN global_comment_notifications VARCHAR(50) DEFAULT 'EVERYONE',
ADD COLUMN global_reply_notifications VARCHAR(50) DEFAULT 'EVERYONE',
ADD COLUMN message_notifications VARCHAR(50) DEFAULT 'ALL_FRIENDS',
ADD COLUMN allow_new_chats VARCHAR(50) DEFAULT 'ALL_FRIENDS',
ADD CONSTRAINT chk_global_react CHECK (global_reaction_notifications IN ('EVERYONE', 'FRIENDS', 'BUBBLE_MEMBERS', 'FRIENDS_AND_BUBBLES', 'BEST_FRIENDS', 'BEST_FRIENDS_AND_BUBBLES', 'NOBODY')),
ADD CONSTRAINT chk_global_comm CHECK (global_comment_notifications IN ('EVERYONE', 'FRIENDS', 'BUBBLE_MEMBERS', 'FRIENDS_AND_BUBBLES', 'BEST_FRIENDS', 'BEST_FRIENDS_AND_BUBBLES', 'NOBODY')),
ADD CONSTRAINT chk_global_repl CHECK (global_reply_notifications IN ('EVERYONE', 'FRIENDS', 'BUBBLE_MEMBERS', 'FRIENDS_AND_BUBBLES', 'BEST_FRIENDS', 'BEST_FRIENDS_AND_BUBBLES', 'NOBODY')),
ADD CONSTRAINT chk_msg_notif CHECK (message_notifications IN ('ALL_FRIENDS', 'BEST_FRIENDS', 'NOBODY')),
ADD CONSTRAINT chk_allow_chats CHECK (allow_new_chats IN ('ALL_FRIENDS', 'BEST_FRIENDS', 'NOBODY'));
