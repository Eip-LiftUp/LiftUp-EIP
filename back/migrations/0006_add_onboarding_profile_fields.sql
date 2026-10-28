-- Migration: 0006_add_onboarding_profile_fields
-- Description: Add fields collected by the first-launch onboarding form
--   (mandatory activity frequency, optional injury/medical notes, optional
--   training focus areas) plus a flag tracking whether the wizard was completed.

ALTER TABLE users
ADD COLUMN activity_frequency VARCHAR(20)
    CHECK (activity_frequency IN ('sedentary', 'light', 'moderate', 'active', 'very_active')),
ADD COLUMN has_injuries BOOLEAN,
ADD COLUMN medical_notes TEXT,
ADD COLUMN training_focus TEXT[],
ADD COLUMN onboarding_completed BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN users.activity_frequency IS 'Self-reported training frequency, collected on the mandatory first onboarding page';
COMMENT ON COLUMN users.has_injuries IS 'Whether the user reported current/past injuries (optional, skippable page)';
COMMENT ON COLUMN users.medical_notes IS 'Free-text medical history shared voluntarily by the user (optional, skippable page)';
COMMENT ON COLUMN users.training_focus IS 'Body zones / training goals the user wants to focus on (optional, skippable page, editable later)';
COMMENT ON COLUMN users.onboarding_completed IS 'Whether the user has been through the first-launch onboarding wizard at least once';
