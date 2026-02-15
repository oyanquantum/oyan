-- Vocabulary table for OYAN. Run in Supabase Dashboard → SQL Editor.
-- Words persist per user across sign out, app restart, and device changes.

-- Create table
CREATE TABLE IF NOT EXISTS vocabulary_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word text NOT NULL,
  translation_en text NOT NULL,
  translation_ru text NOT NULL,
  lesson_index int NOT NULL,
  UNIQUE (user_id, word)
);

-- Index for fast lookup by user
CREATE INDEX IF NOT EXISTS idx_vocabulary_entries_user_id
  ON vocabulary_entries (user_id);

-- Enable RLS
ALTER TABLE vocabulary_entries ENABLE ROW LEVEL SECURITY;

-- Allow anon to insert
DROP POLICY IF EXISTS "Allow anon insert vocabulary_entries" ON vocabulary_entries;
CREATE POLICY "Allow anon insert vocabulary_entries" ON vocabulary_entries
  FOR INSERT TO anon WITH CHECK (true);

-- Allow anon to select
DROP POLICY IF EXISTS "Allow anon select vocabulary_entries" ON vocabulary_entries;
CREATE POLICY "Allow anon select vocabulary_entries" ON vocabulary_entries
  FOR SELECT TO anon USING (true);

-- Allow anon to delete (user can remove words)
DROP POLICY IF EXISTS "Allow anon delete vocabulary_entries" ON vocabulary_entries;
CREATE POLICY "Allow anon delete vocabulary_entries" ON vocabulary_entries
  FOR DELETE TO anon USING (true);
