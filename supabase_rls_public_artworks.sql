-- =====================================================
-- RLS FIX FOR PUBLIC ARTWORK ACCESS (QR CODE SCANNING)
-- Allow anonymous/guest users to view approved artworks
-- =====================================================

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "public_select_approved_artworks" ON public.artworks;
DROP POLICY IF EXISTS "anon_select_approved_artworks" ON public.artworks;

-- Create policy for anonymous users to view APPROVED artworks only
CREATE POLICY "anon_select_approved_artworks"
ON public.artworks
FOR SELECT
TO anon
USING (status = 'approved');

-- Also allow authenticated users to select all artworks (existing policy)
-- This should already exist, but adding for completeness
DROP POLICY IF EXISTS "authenticated_select_artworks" ON public.artworks;
CREATE POLICY "authenticated_select_artworks"
ON public.artworks
FOR SELECT
TO authenticated
USING (true);

-- =====================================================
-- USERS TABLE - Allow public to view user profiles
-- (needed for artwork detail page to show artist info)
-- =====================================================

DROP POLICY IF EXISTS "anon_select_users" ON public.users;
CREATE POLICY "anon_select_users"
ON public.users
FOR SELECT
TO anon
USING (true);

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check approved artworks (these should be visible to anonymous users)
SELECT id, title, status, artist_id 
FROM public.artworks 
WHERE status = 'approved'
LIMIT 5;

-- Check all RLS policies on artworks table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'artworks';

-- Check all RLS policies on users table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users';
