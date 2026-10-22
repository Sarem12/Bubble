ALTER TABLE auth_identities
DROP CONSTRAINT valid_provider;

ALTER TABLE auth_identities
ADD CONSTRAINT valid_provider CHECK(provider IN ('email','phone','google','username'));
