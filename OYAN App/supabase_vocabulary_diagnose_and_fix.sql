-- OYAN vocabulary: diagnose and fix "same for everyone" issue
-- Run in Supabase Dashboard → SQL Editor

-- =============================================================================
-- STEP 1: DIAGNOSE - run these to see what's in the table
-- =============================================================================

-- How many vocabulary entries per user?
SELECT user_id, COUNT(*) AS word_count
FROM vocabulary_entries
GROUP BY user_id
ORDER BY word_count DESC;

-- If you see only ONE user_id with all rows, that's the bug: everything was
-- saved under one user. Different app users would then all see the same vocab
-- if the app was incorrectly using a shared/fixed user_id when fetching.

-- Total rows and distinct users
SELECT
  COUNT(*) AS total_entries,
  COUNT(DISTINCT user_id) AS distinct_users
FROM vocabulary_entries;

-- Sample of what each user has (first 5 words per user)
SELECT user_id, word, translation_en, lesson_index
FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY lesson_index, word) AS rn
  FROM vocabulary_entries
) sub
WHERE rn <= 5
ORDER BY user_id, lesson_index, word;


-- =============================================================================
-- STEP 2: FIX - use ONE of these options
-- =============================================================================

-- Option A: RESET ALL VOCABULARY (everyone starts fresh)
-- Use this if all data was saved under one user and you can't assign rows
-- to the correct users. Users will re-earn words as they complete lessons.
/*
TRUNCATE vocabulary_entries RESTART IDENTITY;
*/

-- Option B: DELETE only entries that belong to a specific "wrong" user
-- Replace 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' with the user_id that
-- incorrectly has everyone's vocabulary.
/*
DELETE FROM vocabulary_entries
WHERE user_id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'::uuid;
*/


-- NOTE: OYAN uses a custom users table (not Supabase Auth), so RLS can't easily
-- filter by "current user" server-side. The app must pass the correct user_id
-- in each request. Ensure currentUserId in the app is set correctly when the
-- user logs in and when switching accounts.
