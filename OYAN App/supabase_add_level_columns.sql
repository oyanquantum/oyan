-- Run this in Supabase Dashboard → SQL Editor to add level columns to the users table.
-- num_level: numeric level calculated by the app (e.g. lesson progress 1–12).
-- level: tier — 'beginner', 'intermediate', or 'advanced'.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS num_level integer,
  ADD COLUMN IF NOT EXISTS level text;

-- Optional: add a check so level only accepts the three tiers
-- ALTER TABLE users ADD CONSTRAINT users_level_check CHECK (level IS NULL OR level IN ('beginner', 'intermediate', 'advanced'));
