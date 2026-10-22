ALTER TABLE networks DROP CONSTRAINT valid_network_type;
ALTER TABLE networks ADD CONSTRAINT valid_network_type CHECK (type IN ('PRIVATE', 'PUBLIC', 'PERSON'));
