-- ============================================================================
-- FIX FOREIGN KEY CONSTRAINT PADA TABEL PROFILES + AUTO TRIGGER
-- ============================================================================
-- Masalah: profiles.id mengacu ke public.users, seharusnya ke auth.users
-- Solusi: 
--   1. Hapus constraint lama, buat constraint baru yang benar
--   2. Buat trigger untuk auto-populate profiles dari auth.users
-- ============================================================================

-- LANGKAH 1: Hapus foreign key constraint yang salah
-- ====================================================
ALTER TABLE public.profiles 
DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- LANGKAH 2: Buat foreign key constraint yang benar (mengacu ke auth.users)
-- ============================================================================
ALTER TABLE public.profiles
ADD CONSTRAINT profiles_id_fkey 
FOREIGN KEY (id) REFERENCES auth.users(id) 
ON DELETE CASCADE;

-- LANGKAH 3: Buat function untuk auto-populate profiles
-- ========================================================
-- OPSI A: Jika profiles TIDAK punya FK ke public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert ke profiles dengan data dari raw_user_meta_data
  INSERT INTO public.profiles (id, role, username, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'viewer'),
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.email),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    role = COALESCE(NEW.raw_user_meta_data->>'role', 'viewer'),
    username = COALESCE(NEW.raw_user_meta_data->>'username', NEW.email);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- OPSI B: Jika profiles PUNYA FK ke public.users (GUNAKAN INI!)
-- Ganti function di atas dengan yang ini:
CREATE OR REPLACE FUNCTION public.handle_new_user_with_users_fk()
RETURNS TRIGGER AS $$
BEGIN
  -- Jangan insert ke profiles dulu, biarkan Flutter yang handle
  -- Karena profiles butuh data dari public.users dulu
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- LANGKAH 4: Buat trigger yang akan dijalankan SETELAH insert ke public.users
-- ================================================================================
-- Hapus trigger lama dari auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Buat trigger baru pada public.users (lebih aman!)
DROP TRIGGER IF EXISTS on_users_insert ON public.users;

CREATE TRIGGER on_users_insert
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Update function untuk ambil data dari public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert ke profiles dengan data dari public.users
  INSERT INTO public.profiles (id, role, username, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.role, 'viewer'), -- Ambil role dari tabel users
    COALESCE(NEW.name, SPLIT_PART(NEW.email, '@', 1)), -- Ambil name dari tabel users
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    role = COALESCE(NEW.role, profiles.role),
    username = COALESCE(NEW.name, profiles.username);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VERIFIKASI: Cek apakah constraint dan trigger sudah benar
-- ============================================================================

-- 1. Cek Foreign Key Constraint
SELECT 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'profiles'
  AND kcu.column_name = 'id';

-- 2. Cek apakah trigger sudah aktif
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table, 
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- ============================================================================
-- CATATAN PENTING:
-- ============================================================================
-- Setelah menjalankan script ini:
-- 1. Setiap kali auth.signUp() dipanggil, trigger akan otomatis:
--    - Ambil data dari parameter 'data' (raw_user_meta_data)
--    - Insert ke profiles dengan role dan username dari metadata
--    - Jika profiles sudah ada, skip (ON CONFLICT DO NOTHING)
--
-- 2. Urutan eksekusi:
--    a. supabase.auth.signUp(data: {...}) → masuk ke auth.users
--    b. TRIGGER otomatis insert ke profiles ✓
--    c. Kode Flutter insert ke users (tabel aplikasi) ✓
--
-- 3. Tidak perlu manual insert ke profiles di kode Flutter lagi!
-- ============================================================================
