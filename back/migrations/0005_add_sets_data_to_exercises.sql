-- Migration 0005: Add sets_data JSON column to exercises
--
-- This migration adds support for storing individual set data (weight, reps, completed status)
-- as a JSON array, enabling tracking of each set separately like in Hevy app.

-- Add sets_data column to store individual set information
ALTER TABLE exercises
ADD COLUMN sets_data JSONB;

-- Add index for JSONB queries (optional but recommended for performance)
CREATE INDEX idx_exercises_sets_data ON exercises USING GIN (sets_data);

-- Add comment explaining the structure
COMMENT ON COLUMN exercises.sets_data IS 'JSON array of individual sets with structure: [{"setNumber": 1, "reps": 10, "weight": 50.0, "isCompleted": true}, ...]';
