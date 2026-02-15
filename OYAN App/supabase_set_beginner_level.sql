-- Run in Supabase → SQL Editor to fix NULL level and set default for "Start from beginning" users.

-- 1) Set level = 'beginner' for all users where level is NULL (fixes existing rows)
UPDATE users
SET level = 'beginner'
WHERE level IS NULL;

-- 2) Optional: default new rows to 'beginner' so inserts get it if column is omitted
ALTER TABLE users
ALTER COLUMN level SET DEFAULT 'beginner';
