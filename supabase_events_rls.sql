-- ========================================
-- RLS POLICIES FOR EVENTS TABLE
-- ========================================
-- File: supabase_events_rls.sql
-- Purpose: Row Level Security policies untuk tabel events
-- Created: For Event Moderation Feature
-- ========================================

-- 1. Enable RLS on events table
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies if any (cleanup)
DROP POLICY IF EXISTS "authenticated_select_all_events" ON events;
DROP POLICY IF EXISTS "artist_insert_own_event" ON events;
DROP POLICY IF EXISTS "authenticated_update_events" ON events;
DROP POLICY IF EXISTS "authenticated_delete_events" ON events;

-- 3. Create new simple policies

-- Policy 1: Allow all authenticated users to SELECT events
-- (Artists can see their own events, admins can see all events)
CREATE POLICY "authenticated_select_all_events" ON events
FOR SELECT
TO authenticated
USING (true);

-- Policy 2: Allow artists to INSERT their own events
-- (Artist ID must match auth.uid())
CREATE POLICY "artist_insert_own_event" ON events
FOR INSERT
TO authenticated
WITH CHECK (artist_id = auth.uid());

-- Policy 3: Allow all authenticated users to UPDATE events
-- (Admins can approve/reject, artists might edit their pending events)
CREATE POLICY "authenticated_update_events" ON events
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy 4: Allow all authenticated users to DELETE events
-- (Admins can delete any event, artists might delete their own)
CREATE POLICY "authenticated_delete_events" ON events
FOR DELETE
TO authenticated
USING (true);

-- ========================================
-- VERIFICATION QUERIES
-- ========================================
-- Check if policies are created correctly:
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'events';

-- Test query (run as authenticated user):
-- SELECT * FROM events WHERE status = 'pending';

-- ========================================
-- NOTES
-- ========================================
-- 1. These policies are intentionally permissive (USING true) to avoid recursion issues
-- 2. Application logic should handle permission checks (e.g., role validation)
-- 3. For stricter security, you can modify policies to check user roles:
--    Example: USING (auth.uid() IN (SELECT id FROM users WHERE role = 'admin'))
-- 4. If you need different permissions for artists vs admins, add role checks:
--    Example: WITH CHECK (artist_id = auth.uid() OR EXISTS (
--                SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'
--              ))
-- ========================================
