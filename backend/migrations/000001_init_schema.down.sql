-- Drop tables in reverse order of creation to prevent Foreign Key errors
DROP TABLE IF EXISTS reactions;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS bubbles;
DROP TABLE IF EXISTS auth_identities;
DROP TABLE IF EXISTS users;