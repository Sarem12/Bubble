ALTER TABLE networks ADD COLUMN member_key VARCHAR(255);

ALTER TABLE friendships 
ADD COLUMN invite_state VARCHAR(20) DEFAULT 'AUTOMATIC' CHECK (invite_state IN ('EVERYCASE', 'NOCASE', 'AUTOMATIC')),
ADD COLUMN invite_exception_bubbles UUID[] DEFAULT '{}';

CREATE TABLE network_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    network_id UUID REFERENCES networks(id) ON DELETE CASCADE,
    inviter_id UUID REFERENCES users(id) ON DELETE CASCADE,
    invitee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(network_id, inviter_id, invitee_id)
);
