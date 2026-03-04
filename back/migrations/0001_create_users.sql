-- Migration: 0001_create_users
-- Description: Create the users table to store user profiles
-- Issue: #30 - User registration endpoint

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email         VARCHAR(255) NOT NULL UNIQUE,
    username      VARCHAR(100) NOT NULL,
    display_name  VARCHAR(255),
    birth_date    DATE,
    height_cm     SMALLINT CHECK (height_cm > 0 AND height_cm < 300),
    weight_kg     NUMERIC(5, 2) CHECK (weight_kg > 0 AND weight_kg < 700),
    fitness_level VARCHAR(20) NOT NULL DEFAULT 'beginner'
                  CHECK (fitness_level IN ('beginner', 'intermediate', 'advanced')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for email lookups
CREATE INDEX idx_users_email ON users (email);

-- Automatically update updated_at on row modification
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_updated_at();
