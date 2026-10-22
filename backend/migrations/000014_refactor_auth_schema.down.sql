CREATE TABLE auth_identities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    identifier VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255), 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_provider CHECK (provider IN ('email', 'phone', 'google', 'apple')),
    UNIQUE(provider, identifier)
);
ALTER TABLE auth_identities ADD CONSTRAINT unique_user_provider UNIQUE (user_id, provider);

-- Backfill data back to auth_identities
INSERT INTO auth_identities (user_id, provider, identifier, password_hash, created_at)
SELECT a.user_id, p.provider, p.identifier, a.password_hash, p.created_at
FROM auth_providers p
JOIN auth a ON a.id = p.auth_id;

DROP TABLE IF EXISTS auth_providers CASCADE;
DROP TABLE IF EXISTS auth CASCADE;
