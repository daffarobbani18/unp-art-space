-- =====================================================
-- FIX RLS POLICIES UNTUK ADMIN DASHBOARD
-- Jalankan di Supabase SQL Editor
-- =====================================================

-- 1. HAPUS POLICIES LAMA JIKA ADA (agar tidak konflik)
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

-- 2. ENABLE RLS (jika belum aktif)
ALTER TABLE public.artworks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 3. POLICY UNTUK ADMIN - READ ALL ARTWORKS
-- Gunakan subquery yang aman tanpa recursion
CREATE POLICY "admin_select_artworks"
ON public.artworks
FOR SELECT
TO authenticated
USING (
  -- Admin bisa lihat semua artwork
  EXISTS (
    SELECT 1 FROM public.profiles p 
    WHERE p.id = auth.uid() 
    AND p.role = 'admin'
  )
  OR
  -- Artist bisa lihat artwork sendiri
  artist_id = auth.uid()
  OR
  -- Semua user bisa lihat artwork yang approved
  status IN ('approved', 'disetujui')
);

-- 4. POLICY UNTUK ADMIN - UPDATE ANY ARTWORK (approve/reject/delete)
CREATE POLICY "admin_update_artworks"
ON public.artworks
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    WHERE p.id = auth.uid() 
    AND p.role = 'admin'
  )
)
WITH CHECK (true);

-- 5. POLICY UNTUK ADMIN - DELETE ANY ARTWORK
CREATE POLICY "admin_delete_artworks"
ON public.artworks
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p 
    WHERE p.id = auth.uid() 
    AND p.role = 'admin'
  )
);

-- 6. POLICY UNTUK ARTIST - INSERT OWN ARTWORK
CREATE POLICY "artist_insert_own_artwork"
ON public.artworks
FOR INSERT
TO authenticated
WITH CHECK (
  artist_id = auth.uid()
);

-- 7. POLICY UNTUK ARTIST - SELECT OWN ARTWORKS
-- Sudah termasuk di policy admin_select_artworks

-- 8. POLICY UNTUK PUBLIC - SELECT APPROVED ARTWORKS  
-- Sudah termasuk di policy admin_select_artworks

-- 9. POLICY UNTUK USERS TABLE - SEMUA AUTHENTICATED USER BISA BACA
-- Ini yang paling aman untuk menghindari infinite recursion
CREATE POLICY "authenticated_select_users"
ON public.users
FOR SELECT
TO authenticated
USING (true);

-- 10. POLICY UNTUK USER - UPDATE OWN PROFILE
CREATE POLICY "user_update_self"
ON public.users
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 11. HAPUS DEFAULT gen_random_uuid() PADA artist_id (berbahaya!)
ALTER TABLE public.artworks 
ALTER COLUMN artist_id DROP DEFAULT;

-- 12. TAMBAHKAN FOREIGN KEY CONSTRAINT (opsional tapi disarankan)
-- Uncomment jika ingin menambahkan foreign key
-- ALTER TABLE public.artworks
-- ADD CONSTRAINT artworks_artist_id_fkey
-- FOREIGN KEY (artist_id) 
-- REFERENCES public.users(id) 
-- ON DELETE CASCADE;

-- =====================================================
-- UPDATE STATUS LAMA KE FORMAT BARU (WAJIB!)
-- Jalankan ini untuk mengubah status lama ke format baru
-- =====================================================

-- Update status dari bahasa Indonesia ke English
UPDATE public.artworks SET status = 'approved' WHERE status = 'disetujui';
UPDATE public.artworks SET status = 'pending' WHERE status = 'menunggu_persetujuan';
UPDATE public.artworks SET status = 'rejected' WHERE status = 'ditolak';

-- Pastikan tidak ada status lain yang aneh
UPDATE public.artworks SET status = 'pending' WHERE status NOT IN ('pending', 'approved', 'rejected');

-- =====================================================
-- VERIFICATION QUERIES
-- Jalankan setelah policies di atas berhasil
-- =====================================================

-- Query 1: Cek total artworks per status
SELECT status, COUNT(*) as total
FROM public.artworks
GROUP BY status
ORDER BY status;

-- Query 2: Lihat 10 artworks terbaru
SELECT 
  id,
  title,
  status,
  artist_id,
  created_at
FROM public.artworks
ORDER BY created_at DESC
LIMIT 10;

-- Query 3: Cek apakah ada artworks dengan artist_id yang tidak ada di users
SELECT 
  a.id,
  a.title,
  a.artist_id,
  u.name as artist_name
FROM public.artworks a
LEFT JOIN public.users u ON a.artist_id = u.id
WHERE u.id IS NULL;

-- Query 4: Lihat semua users dengan role admin
SELECT id, name, email, role
FROM public.users
WHERE role = 'admin';

-- Query 5: Lihat semua policies yang aktif
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename IN ('artworks', 'users')
ORDER BY tablename, policyname;
