-- Migration: 0002_add_password_to_users
-- Description: Add password_hash column to users table for authentication

ALTER TABLE users
ADD COLUMN password_hash VARCHAR(255) NOT NULL DEFAULT '';

-- Remove default after adding the column (future inserts must provide it)
ALTER TABLE users
ALTER COLUMN password_hash DROP DEFAULT;
