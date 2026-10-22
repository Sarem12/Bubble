ALTER table auth_identities
DROP CONSTRAINT valid_provider;

ALTER table auth_identities
ADD CONSTRAINT valid_provider CHECK(provider IN ('email','phone','google','apple'));
