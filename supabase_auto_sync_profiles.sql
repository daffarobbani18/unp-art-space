-- ===================================================================
-- AUTO SYNC PROFILES TABLE - Database Trigger
-- ===================================================================
-- File ini berisi trigger untuk otomatis sync data ke profiles table
-- setiap ada user baru di auth.users atau insert di public.users
-- ===================================================================

-- OPSI 1: Trigger dari auth.users (Recommended)
-- ===================================================================
-- Trigger ini akan otomatis insert ke profiles saat ada user baru
-- di auth.users table (Supabase Authentication)

-- Function untuk handle insert ke profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert ke profiles dengan data dari new user
  INSERT INTO public.profiles (id, role, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'viewer'), -- Default viewer jika tidak ada role
    COALESCE(NEW.raw_user_meta_data->>'name', SPLIT_PART(NEW.email, '@', 1)) -- Gunakan email prefix sebagai username default
  )
  ON CONFLICT (id) DO NOTHING; -- Skip jika sudah ada
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Buat trigger pada auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ===================================================================
-- OPSI 2: Trigger dari public.users (Alternative)
-- ===================================================================
-- Trigger ini akan otomatis insert ke profiles saat ada insert
-- ke public.users table

-- Function untuk sync dari users ke profiles
CREATE OR REPLACE FUNCTION public.sync_users_to_profiles()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert atau update profiles berdasarkan data dari users
  INSERT INTO public.profiles (id, role, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.role, 'viewer'),
    COALESCE(NEW.name, SPLIT_PART(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO UPDATE SET
    role = COALESCE(EXCLUDED.role, public.profiles.role),
    username = COALESCE(EXCLUDED.username, public.profiles.username);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Buat trigger pada public.users
DROP TRIGGER IF EXISTS on_users_insert_or_update ON public.users;
CREATE TRIGGER on_users_insert_or_update
  AFTER INSERT OR UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_users_to_profiles();

-- ===================================================================
-- MANUAL SYNC - Untuk data existing
-- ===================================================================
-- Query ini untuk sync data yang sudah ada di users tapi belum di profiles

-- Lihat users yang belum ada di profiles
SELECT u.id, u.name, u.email, u.role
FROM public.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- Insert bulk data dari users ke profiles (jika ada yang missing)
INSERT INTO public.profiles (id, role, username)
SELECT 
  u.id,
  COALESCE(u.role, 'viewer') as role,
  COALESCE(u.name, SPLIT_PART(u.email, '@', 1)) as username
FROM public.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- ===================================================================
-- VERIFICATION QUERIES
-- ===================================================================

-- Check apakah trigger aktif
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public' 
  AND (trigger_name LIKE '%user%' OR trigger_name LIKE '%profile%');

-- Count data di users vs profiles
SELECT 
  'users' as table_name,
  COUNT(*) as total
FROM public.users
UNION ALL
SELECT 
  'profiles' as table_name,
  COUNT(*) as total
FROM public.profiles;

-- Lihat mismatch data (user ada tapi profiles tidak)
SELECT 
  u.id,
  u.name,
  u.email,
  u.role as user_role,
  p.role as profile_role,
  CASE 
    WHEN p.id IS NULL THEN 'Missing in profiles'
    WHEN u.role != p.role THEN 'Role mismatch'
    ELSE 'OK'
  END as status
FROM public.users u
FULL OUTER JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL OR u.role != p.role;

-- ===================================================================
-- CLEANUP (Jika perlu hapus trigger)
-- ===================================================================

-- Hapus trigger dari auth.users
-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- DROP FUNCTION IF EXISTS public.handle_new_user();

-- Hapus trigger dari public.users
-- DROP TRIGGER IF EXISTS on_users_insert_or_update ON public.users;
-- DROP FUNCTION IF EXISTS public.sync_users_to_profiles();

-- ===================================================================
-- CATATAN IMPLEMENTASI
-- ===================================================================
-- 
-- RECOMMENDED APPROACH:
-- 1. Gunakan Trigger OPSI 1 (auth.users) untuk auto-sync dari Supabase Auth
-- 2. Gunakan Trigger OPSI 2 (public.users) sebagai backup jika insert langsung ke users table
-- 3. Jalankan MANUAL SYNC untuk data existing yang belum ada di profiles
--
-- TESTING:
-- 1. Buat user baru via register page
-- 2. Check apakah data masuk ke users DAN profiles
-- 3. Verify role dan username sudah sesuai
--
-- NOTES:
-- - Trigger akan otomatis handle new user registration
-- - Code di register_page.dart tetap insert ke profiles (double safety)
-- - ON CONFLICT DO NOTHING mencegah error jika sudah ada
-- - SECURITY DEFINER allows trigger to bypass RLS
