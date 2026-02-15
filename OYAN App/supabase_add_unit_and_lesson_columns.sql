-- Run this in Supabase Dashboard → SQL Editor (paste and click Run).
-- Adds columns for current unit and lesson (level already exists).

-- num_level = current lesson (cloud index 1–11). User on lesson 2 has num_level 2; not started = 1.
-- current_unit = current unit (1–3). Derived from the lesson.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS num_level integer,
  ADD COLUMN IF NOT EXISTS current_unit integer;
