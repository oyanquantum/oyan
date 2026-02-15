-- Chat messages table for OYAN. Run in Supabase Dashboard → SQL Editor.
-- Messages persist per user across sign out, app restart, and device changes.

-- Create table
CREATE TABLE IF NOT EXISTS chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('user', 'assistant')),
  text text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Index for fast lookup by user
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id_created_at
  ON chat_messages (user_id, created_at ASC);

-- Enable RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Allow anon to insert (app passes user_id from logged-in user)
DROP POLICY IF EXISTS "Allow anon insert chat_messages" ON chat_messages;
CREATE POLICY "Allow anon insert chat_messages" ON chat_messages
  FOR INSERT TO anon WITH CHECK (true);

-- Allow anon to select (app filters by user_id in query)
DROP POLICY IF EXISTS "Allow anon select chat_messages" ON chat_messages;
CREATE POLICY "Allow anon select chat_messages" ON chat_messages
  FOR SELECT TO anon USING (true);

-- Optional: allow delete so user can clear chat
DROP POLICY IF EXISTS "Allow anon delete own chat_messages" ON chat_messages;
CREATE POLICY "Allow anon delete own chat_messages" ON chat_messages
  FOR DELETE TO anon USING (true);
