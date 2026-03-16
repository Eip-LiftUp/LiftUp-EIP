-- Migration 0002: Create workouts and exercises tables
--
-- This migration creates tables for storing user workout sessions and exercises.
-- Inspired by Hevy app structure.

-- Table: workouts
-- Stores workout sessions for users
CREATE TABLE IF NOT EXISTS workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    workout_date DATE NOT NULL DEFAULT CURRENT_DATE,
    duration_minutes INTEGER,
    notes TEXT,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster queries by user and date
CREATE INDEX idx_workouts_user_id ON workouts(user_id);
CREATE INDEX idx_workouts_date ON workouts(workout_date);
CREATE INDEX idx_workouts_user_date ON workouts(user_id, workout_date);

-- Table: exercises
-- Stores individual exercises within a workout
CREATE TABLE IF NOT EXISTS exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_name VARCHAR(255) NOT NULL,
    sets INTEGER NOT NULL DEFAULT 3,
    reps INTEGER NOT NULL DEFAULT 10,
    weight NUMERIC(6, 2),
    weight_unit VARCHAR(10) NOT NULL DEFAULT 'kg' CHECK (weight_unit IN ('kg', 'lbs')),
    order_index INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster queries by workout
CREATE INDEX idx_exercises_workout_id ON exercises(workout_id);
CREATE INDEX idx_exercises_order ON exercises(workout_id, order_index);
