-- ============================================================================
-- UPDATE DATABASE UNTUK MENDUKUNG ROLE ORGANIZER DI REGISTRASI
-- ============================================================================
-- File ini meng-update trigger dan function agar mendukung role 'organizer'
-- yang dikirim dari parameter data saat registrasi
-- ============================================================================

-- LANGKAH 1: Update function handle_new_user untuk mendukung semua role
-- ========================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert ke profiles dengan data dari public.users
  -- Support untuk role: viewer, artist, organizer
  INSERT INTO public.profiles (id, role, username, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.role, 'viewer'), -- Ambil role dari tabel users (viewer/artist/organizer)
    COALESCE(NEW.name, SPLIT_PART(NEW.email, '@', 1)), -- Ambil name dari tabel users
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    role = COALESCE(NEW.role, profiles.role),
    username = COALESCE(NEW.name, profiles.username);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- LANGKAH 2: Pastikan trigger sudah aktif pada tabel users
-- ===========================================================
-- Hapus trigger lama jika ada
DROP TRIGGER IF EXISTS on_users_insert ON public.users;

-- Buat trigger baru
CREATE TRIGGER on_users_insert
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- LANGKAH 3: Pastikan constraint role di profiles mendukung 'organizer'
-- ========================================================================
-- Check constraint sudah ada di schema.sql Anda:
-- role text DEFAULT '''user'''::text CHECK (role = ANY (ARRAY['admin'::text, 'artist'::text, 'viewer'::text, 'organizer'::text]))
-- Jika belum ada, uncomment script di bawah:

-- ALTER TABLE public.profiles
-- DROP CONSTRAINT IF EXISTS profiles_role_check;

-- ALTER TABLE public.profiles
-- ADD CONSTRAINT profiles_role_check 
-- CHECK (role = ANY (ARRAY['admin'::text, 'artist'::text, 'viewer'::text, 'organizer'::text]));

-- ============================================================================
-- VERIFIKASI: Cek apakah semuanya sudah benar
-- ============================================================================

-- 1. Cek apakah trigger aktif
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table, 
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE trigger_name = 'on_users_insert' 
  AND event_object_table = 'users';

-- 2. Cek constraint role di profiles
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.profiles'::regclass
  AND conname LIKE '%role%';

-- 3. Test insert manual (OPTIONAL - untuk testing)
-- Ganti UUID dengan ID user yang valid dari auth.users
/*
INSERT INTO public.users (id, name, email, role, created_at)
VALUES (
    'TEST-UUID-HERE'::uuid,
    'Test Organizer',
    'test@organizer.com',
    'organizer',
    NOW()
);

-- Check apakah otomatis masuk ke profiles
SELECT * FROM public.profiles WHERE id = 'TEST-UUID-HERE'::uuid;
*/

-- ============================================================================
-- CATATAN PENTING:
-- ============================================================================
-- Setelah menjalankan script ini:
--
-- 1. Alur registrasi yang benar:
--    a. User mengisi form registrasi di app (pilih role: viewer/artist/organizer)
--    b. supabase.auth.signUp(data: {'role': 'organizer', ...}) → masuk ke auth.users
--    c. Flutter insert ke public.users dengan role
--    d. TRIGGER otomatis insert ke public.profiles ✅
--
-- 2. Role yang didukung:
--    - viewer: Penikmat seni (default)
--    - artist: Kreator karya (butuh spesialisasi)
--    - organizer: Event organizer/panitia
--    - admin: (hanya bisa dibuat manual oleh super admin)
--
-- 3. Navigasi otomatis setelah registrasi:
--    - organizer → /organizer_home
--    - artist/viewer → /home
--
-- 4. Trigger ini berjalan SETELAH insert ke users berhasil, sehingga:
--    - Tidak ada race condition
--    - Data di profiles selalu sinkron dengan users
--    - ON CONFLICT DO UPDATE memastikan data selalu ter-update
--
-- ============================================================================
