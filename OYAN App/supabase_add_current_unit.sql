-- Run this in Supabase Dashboard → SQL Editor.
-- current_unit: unit the user is currently on (1–3). Matches the lesson at num_level.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS current_unit integer;

-- Optional: keep in sync with num_level (1–11) so unit is 1–3
-- ALTER TABLE users ADD CONSTRAINT users_current_unit_check CHECK (current_unit IS NULL OR (current_unit >= 1 AND current_unit <= 3));
