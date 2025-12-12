-- Migration: Add power_student role
-- Description: Adds 'power_student' to the allowed roles in app_user table

-- Drop the existing constraint
ALTER TABLE public.app_user DROP CONSTRAINT IF EXISTS app_user_role_check;

-- Add the new constraint with power_student included
ALTER TABLE public.app_user ADD CONSTRAINT app_user_role_check
    CHECK ((role = ANY (ARRAY['student'::text, 'teacher'::text, 'admin'::text, 'power_student'::text])));

-- Commit message: Add power_student role to database schema
