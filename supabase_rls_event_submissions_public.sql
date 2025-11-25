-- =====================================================
-- RLS FIX FOR EVENT SUBMISSIONS PUBLIC ACCESS
-- Allow anonymous users to view event submissions for QR code scanning
-- =====================================================

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "anon_select_event_submissions" ON public.event_submissions;
DROP POLICY IF EXISTS "public_select_event_submissions" ON public.event_submissions;

-- Enable RLS on event_submissions if not already enabled
ALTER TABLE public.event_submissions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLICY FOR ANONYMOUS USERS (QR CODE SCANNING)
-- =====================================================

-- Allow anonymous users to SELECT event_submissions
-- (needed for QR code scanning from /submission/{uuid})
CREATE POLICY "anon_select_event_submissions"
ON public.event_submissions
FOR SELECT
TO anon
USING (true);

-- =====================================================
-- POLICY FOR AUTHENTICATED USERS
-- =====================================================

-- Allow authenticated users to SELECT all submissions
DROP POLICY IF EXISTS "authenticated_select_event_submissions" ON public.event_submissions;
CREATE POLICY "authenticated_select_event_submissions"
ON public.event_submissions
FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to INSERT their own submissions
DROP POLICY IF EXISTS "artist_insert_event_submissions" ON public.event_submissions;
CREATE POLICY "artist_insert_event_submissions"
ON public.event_submissions
FOR INSERT
TO authenticated
WITH CHECK (artist_id = auth.uid());

-- Allow organizer to UPDATE submissions (approve/reject)
DROP POLICY IF EXISTS "organizer_update_event_submissions" ON public.event_submissions;
CREATE POLICY "organizer_update_event_submissions"
ON public.event_submissions
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check all RLS policies on event_submissions table
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'event_submissions'
ORDER BY policyname;

-- Test query as anonymous user (this should work after running the script)
-- SELECT * FROM event_submissions LIMIT 5;

-- =====================================================
-- NOTES
-- =====================================================

-- This script allows:
-- 1. Anonymous users (QR code scanners) to view event submissions
-- 2. Authenticated users to view all submissions
-- 3. Artists to insert their own submissions
-- 4. Organizers to update submission status (approve/reject)

-- =====================================================
-- USERS TABLE RLS (for artist profile data)
-- =====================================================

-- Enable RLS on users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Allow anonymous users to SELECT users (for artist profile in artwork detail)
DROP POLICY IF EXISTS "anon_select_users" ON public.users;
CREATE POLICY "anon_select_users"
ON public.users
FOR SELECT
TO anon
USING (true);

-- Allow authenticated users to SELECT all users
DROP POLICY IF EXISTS "authenticated_select_users" ON public.users;
CREATE POLICY "authenticated_select_users"
ON public.users
FOR SELECT
TO authenticated
USING (true);

-- =====================================================
-- Make sure to run the artworks RLS policies as well:
-- - supabase_rls_public_artworks.sql (for artwork data access)
-- =====================================================
