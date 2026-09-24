-- Migration: 0007_add_injured_zones
-- Description: Add a structured list of injured body zones, so the AI coach engine
--   can gate/adapt exercise selection without having to parse free-text medical notes.

ALTER TABLE users
ADD COLUMN injured_zones TEXT[];

COMMENT ON COLUMN users.injured_zones IS 'Structured list of body zones the user reported as injured (e.g. Epaules, Genoux). Machine-readable counterpart to the free-text medical_notes field.';
