-- Migration: 0003_add_fitness_goals
-- Description: Add fitness_goals column to store user's fitness objectives

ALTER TABLE users
ADD COLUMN fitness_goals TEXT;

-- Add comment
COMMENT ON COLUMN users.fitness_goals IS 'User fitness goals and objectives (free text)';
