-- Run this in Supabase Dashboard → SQL Editor so the app can save and load user data.
-- Without these policies, Row Level Security (RLS) blocks updates and you stay on registration after login.

-- Enable RLS on users (if not already)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Allow anon to SELECT (login + fetch profile)
DROP POLICY IF EXISTS "Allow anon select users" ON users;
CREATE POLICY "Allow anon select users" ON users FOR SELECT TO anon USING (true);

-- Allow anon to INSERT (sign up)
DROP POLICY IF EXISTS "Allow anon insert users" ON users;
CREATE POLICY "Allow anon insert users" ON users FOR INSERT TO anon WITH CHECK (true);

-- Allow anon to UPDATE (save test result, onboarding, profile, level)
DROP POLICY IF EXISTS "Allow anon update users" ON users;
CREATE POLICY "Allow anon update users" ON users FOR UPDATE TO anon USING (true) WITH CHECK (true);
