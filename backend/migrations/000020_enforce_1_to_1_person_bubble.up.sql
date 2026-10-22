-- Enforce that a user can own AT MOST ONE bubble of type 'PERSON'.
-- This prevents the backend from accidentally creating multiple personal feeds for the same user.
CREATE UNIQUE INDEX unique_person_network_per_user ON networks(owner_id) WHERE type = 'PERSON';
