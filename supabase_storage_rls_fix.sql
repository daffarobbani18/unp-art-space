-- ========================================
-- STORAGE RLS POLICIES FIX
-- ========================================
-- File: supabase_storage_rls_fix.sql
-- Purpose: Fix Row Level Security policies untuk Supabase Storage bucket 'artworks'
-- Problem: Error 403 Unauthorized saat upload event
-- ========================================

-- 1. Check existing policies on artworks bucket
SELECT * FROM storage.policies WHERE bucket_id = 'artworks';

-- 2. Drop existing restrictive policies if any
-- (Run these one by one and ignore errors if policy doesn't exist)
DROP POLICY IF EXISTS "Allow authenticated uploads to artworks" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to artworks" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to upload their own artworks" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own artworks" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own artworks" ON storage.objects;

-- 3. Create new permissive policies for artworks bucket

-- Policy A: Allow authenticated users to INSERT (upload) to artworks bucket
CREATE POLICY "Authenticated users can upload to artworks"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'artworks'
);

-- Policy B: Allow authenticated users to UPDATE their own files
CREATE POLICY "Authenticated users can update their own files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'artworks' AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'artworks' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy C: Allow authenticated users to DELETE their own files
CREATE POLICY "Authenticated users can delete their own files"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'artworks' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy D: Allow public SELECT (read) access to artworks bucket
CREATE POLICY "Public can read artworks"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'artworks'
);

-- ========================================
-- ALTERNATIVE: SIMPLE PERMISSIVE POLICIES
-- ========================================
-- If the above policies still cause issues, use these simpler ones:

-- Drop the complex policies
-- DROP POLICY IF EXISTS "Authenticated users can upload to artworks" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can update their own files" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can delete their own files" ON storage.objects;
-- DROP POLICY IF EXISTS "Public can read artworks" ON storage.objects;

-- Create super permissive policies (NOT RECOMMENDED FOR PRODUCTION)
-- CREATE POLICY "Allow all authenticated INSERT" ON storage.objects
-- FOR INSERT TO authenticated
-- WITH CHECK (bucket_id = 'artworks');

-- CREATE POLICY "Allow all authenticated UPDATE" ON storage.objects
-- FOR UPDATE TO authenticated
-- USING (bucket_id = 'artworks')
-- WITH CHECK (bucket_id = 'artworks');

-- CREATE POLICY "Allow all authenticated DELETE" ON storage.objects
-- FOR DELETE TO authenticated
-- USING (bucket_id = 'artworks');

-- CREATE POLICY "Allow all SELECT" ON storage.objects
-- FOR SELECT TO public
-- USING (bucket_id = 'artworks');

-- ========================================
-- VERIFY BUCKET CONFIGURATION
-- ========================================
-- Check if bucket exists and is public
SELECT id, name, public FROM storage.buckets WHERE name = 'artworks';

-- If bucket doesn't exist, create it:
-- INSERT INTO storage.buckets (id, name, public) 
-- VALUES ('artworks', 'artworks', true);

-- Make bucket public if it's not:
-- UPDATE storage.buckets SET public = true WHERE name = 'artworks';

-- ========================================
-- VERIFICATION QUERIES
-- ========================================
-- Check all policies on artworks bucket:
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
WHERE tablename = 'objects' AND policyname LIKE '%artwork%';

-- Check storage policies:
SELECT * FROM storage.policies WHERE bucket_id = 'artworks';

-- ========================================
-- TESTING
-- ========================================
-- Test upload from your Flutter app after running these policies
-- Path format: events/{user_id}/event_*.jpg
-- Example: events/550e8400-e29b-41d4-a716-446655440000/event_1699355645123.jpg

-- ========================================
-- NOTES
-- ========================================
-- 1. The path format in upload_event_screen.dart is: events/{user_id}/{filename}
-- 2. storage.foldername(name) splits path by '/' and returns array
-- 3. (storage.foldername(name))[1] gets the first folder (user_id)
-- 4. auth.uid()::text converts UUID to text for comparison
-- 5. Make sure bucket 'artworks' is PUBLIC in Supabase dashboard
-- 6. If still having issues, check Supabase logs for detailed error messages
-- ========================================
