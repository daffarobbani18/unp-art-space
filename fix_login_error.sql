-- ============================================================================
-- FIX LOGIN ERROR - Internal Server Error
-- ============================================================================
-- Script ini memperbaiki masalah error 556 dan internal server error
-- yang terjadi saat login dan mengakses profile
-- ============================================================================

-- LANGKAH 1: Periksa dan perbaiki RLS Policy untuk tabel users
-- ============================================================

-- 1.1. Enable RLS pada tabel users (jika belum)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 1.2. Drop existing policies yang mungkin terlalu restrictive
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;

-- 1.3. Buat policy baru yang lebih permissive
-- Policy untuk SELECT (read) - user bisa read profile sendiri dan profile publik
CREATE POLICY "Users can view profiles"
ON public.users FOR SELECT
TO authenticated
USING (true); -- Semua authenticated user bisa lihat semua profile (untuk social features)

-- Policy untuk INSERT - user hanya bisa insert profile sendiri
CREATE POLICY "Users can insert own profile"
ON public.users FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy untuk UPDATE - user hanya bisa update profile sendiri
CREATE POLICY "Users can update own profile"
ON public.users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- LANGKAH 2: Periksa dan perbaiki RLS Policy untuk tabel profiles
-- ================================================================

-- 2.1. Enable RLS pada tabel profiles (jika belum)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2.2. Drop existing policies
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

-- 2.3. Buat policy baru
-- Policy untuk SELECT - semua orang bisa lihat profile (publik)
CREATE POLICY "Profiles are viewable by everyone"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

-- Policy untuk INSERT - user bisa insert profile sendiri
CREATE POLICY "Users can insert own profile"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy untuk UPDATE - user bisa update profile sendiri
CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- LANGKAH 3: Periksa dan perbaiki RLS Policy untuk tabel artworks
-- ================================================================

-- 3.1. Enable RLS pada tabel artworks (jika belum)
ALTER TABLE public.artworks ENABLE ROW LEVEL SECURITY;

-- 3.2. Drop existing policies yang mungkin bermasalah
DROP POLICY IF EXISTS "Artworks are viewable by everyone" ON public.artworks;
DROP POLICY IF EXISTS "Artists can insert artworks" ON public.artworks;
DROP POLICY IF EXISTS "Artists can update own artworks" ON public.artworks;
DROP POLICY IF EXISTS "Artists can delete own artworks" ON public.artworks;

-- 3.3. Buat policy baru
-- Policy untuk SELECT - semua orang bisa lihat artwork yang approved
CREATE POLICY "Artworks are viewable by everyone"
ON public.artworks FOR SELECT
TO authenticated
USING (true); -- Semua user bisa lihat semua artwork

-- Policy untuk INSERT - artist bisa insert artwork
CREATE POLICY "Artists can insert artworks"
ON public.artworks FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = artist_id);

-- Policy untuk UPDATE - artist bisa update artwork sendiri
CREATE POLICY "Artists can update own artworks"
ON public.artworks FOR UPDATE
TO authenticated
USING (auth.uid() = artist_id)
WITH CHECK (auth.uid() = artist_id);

-- Policy untuk DELETE - artist bisa delete artwork sendiri
CREATE POLICY "Artists can delete own artworks"
ON public.artworks FOR DELETE
TO authenticated
USING (auth.uid() = artist_id);

-- LANGKAH 4: Periksa dan perbaiki RLS Policy untuk tabel events
-- ==============================================================

-- 4.1. Enable RLS pada tabel events (jika belum)
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- 4.2. Drop existing policies
DROP POLICY IF EXISTS "Events are viewable by everyone" ON public.events;
DROP POLICY IF EXISTS "Organizers can insert events" ON public.events;
DROP POLICY IF EXISTS "Organizers can update own events" ON public.events;
DROP POLICY IF EXISTS "Organizers can delete own events" ON public.events;

-- 4.3. Buat policy baru
-- Policy untuk SELECT - semua orang bisa lihat event
CREATE POLICY "Events are viewable by everyone"
ON public.events FOR SELECT
TO authenticated
USING (true);

-- Policy untuk INSERT - organizer bisa insert event
CREATE POLICY "Organizers can insert events"
ON public.events FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = organizer_id);

-- Policy untuk UPDATE - organizer bisa update event sendiri
CREATE POLICY "Organizers can update own events"
ON public.events FOR UPDATE
TO authenticated
USING (auth.uid() = organizer_id)
WITH CHECK (auth.uid() = organizer_id);

-- Policy untuk DELETE - organizer bisa delete event sendiri
CREATE POLICY "Organizers can delete own events"
ON public.events FOR DELETE
TO authenticated
USING (auth.uid() = organizer_id);

-- ============================================================================
-- VERIFIKASI
-- ============================================================================

-- Cek semua policies yang aktif
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
WHERE schemaname = 'public'
  AND tablename IN ('users', 'profiles', 'artworks', 'events')
ORDER BY tablename, policyname;

-- Cek RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('users', 'profiles', 'artworks', 'events');

-- ============================================================================
-- CATATAN PENTING:
-- ============================================================================
-- Setelah menjalankan script ini:
-- 1. Restart aplikasi Flutter (hot restart)
-- 2. Coba login lagi
-- 3. Cek console untuk error messages
-- 4. Jika masih error, cek di Supabase Dashboard > Authentication > Policies
-- ============================================================================
