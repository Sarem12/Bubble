ALTER TABLE auth_identities ADD CONSTRAINT unique_user_provider UNIQUE (user_id, provider);
