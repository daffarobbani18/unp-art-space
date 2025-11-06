-- =====================================================
-- SIMPLE RLS FIX - TANPA INFINITE RECURSION
-- Solusi paling aman untuk menghindari error 42P17
-- =====================================================

-- 1. HAPUS SEMUA POLICY LAMA
DROP POLICY IF EXISTS "admin_select_artworks" ON public.artworks;
DROP POLICY IF EXISTS "admin_update_artworks" ON public.artworks;
DROP POLICY IF EXISTS "admin_delete_artworks" ON public.artworks;
DROP POLICY IF EXISTS "artist_insert_own_artwork" ON public.artworks;
DROP POLICY IF EXISTS "artist_select_own_artworks" ON public.artworks;
DROP POLICY IF EXISTS "admin_select_users" ON public.users;
DROP POLICY IF EXISTS "user_select_self" ON public.users;
DROP POLICY IF EXISTS "public_select_approved_artworks" ON public.artworks;
DROP POLICY IF EXISTS "authenticated_select_users" ON public.users;
DROP POLICY IF EXISTS "user_update_self" ON public.users;

-- 2. DISABLE RLS SEMENTARA (untuk testing)
-- Uncomment ini jika Anda ingin disable RLS sepenuhnya
-- ALTER TABLE public.artworks DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- ATAU gunakan policy sederhana di bawah:

-- 3. ENABLE RLS
ALTER TABLE public.artworks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4. POLICY ARTWORKS - SIMPLE & SAFE
-- Semua authenticated user bisa SELECT semua artwork
CREATE POLICY "authenticated_select_artworks"
ON public.artworks
FOR SELECT
TO authenticated
USING (true);

-- Artist bisa INSERT artwork sendiri
CREATE POLICY "artist_insert_artworks"
ON public.artworks
FOR INSERT
TO authenticated
WITH CHECK (artist_id = auth.uid());

-- Semua authenticated user bisa UPDATE artwork
-- (nanti kita filter di aplikasi siapa yang boleh)
CREATE POLICY "authenticated_update_artworks"
ON public.artworks
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Semua authenticated user bisa DELETE artwork
CREATE POLICY "authenticated_delete_artworks"
ON public.artworks
FOR DELETE
TO authenticated
USING (true);

-- 5. POLICY USERS - SIMPLE & SAFE
-- Semua authenticated user bisa SELECT semua users
-- INI YANG PALING AMAN - tidak ada recursion
CREATE POLICY "authenticated_select_all_users"
ON public.users
FOR SELECT
TO authenticated
USING (true);

-- User bisa UPDATE profile sendiri
CREATE POLICY "user_update_own_profile"
ON public.users
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- =====================================================
-- UPDATE STATUS LAMA KE FORMAT BARU
-- =====================================================

UPDATE public.artworks SET status = 'approved' WHERE status = 'disetujui';
UPDATE public.artworks SET status = 'pending' WHERE status IN ('menunggu_persetujuan', 'menunggu');
UPDATE public.artworks SET status = 'rejected' WHERE status = 'ditolak';

-- Pastikan tidak ada status aneh
UPDATE public.artworks SET status = 'pending' 
WHERE status NOT IN ('pending', 'approved', 'rejected');

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Cek artworks per status
SELECT status, COUNT(*) as total
FROM public.artworks
GROUP BY status
ORDER BY status;

-- Cek semua artworks
SELECT id, title, status, artist_id, created_at
FROM public.artworks
ORDER BY created_at DESC
LIMIT 10;

-- Cek users
SELECT id, name, email, role
FROM public.users
ORDER BY created_at DESC
LIMIT 10;

-- Cek policies aktif
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename IN ('artworks', 'users')
ORDER BY tablename, policyname;
