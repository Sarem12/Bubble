CREATE TABLE auth (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE auth_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID NOT NULL REFERENCES auth(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    identifier VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_provider CHECK (provider IN ('email', 'phone', 'google', 'apple')),
    UNIQUE(provider, identifier),
    UNIQUE(auth_id, provider)
);

-- Backfill data from auth_identities (if any existed)
INSERT INTO auth (user_id, password_hash, created_at)
SELECT DISTINCT ON (user_id) user_id, COALESCE(password_hash, 'temp_hash'), created_at 
FROM auth_identities 
ORDER BY user_id, created_at DESC;

INSERT INTO auth_providers (auth_id, provider, identifier, created_at)
SELECT a.id, ai.provider, ai.identifier, ai.created_at
FROM auth_identities ai
JOIN auth a ON a.user_id = ai.user_id;

-- Safely drop old table now
DROP TABLE IF EXISTS auth_identities CASCADE;
