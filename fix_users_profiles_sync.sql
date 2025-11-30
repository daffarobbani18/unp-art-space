-- =============================================================================
-- FIX: Sinkronisasi struktur tabel users dan profiles
-- =============================================================================
-- Masalah:
-- 1. Tabel 'users' tidak punya FK ke auth.users
-- 2. Role duplikasi di 2 tabel
-- 3. Data bisa tidak sinkron
--
-- Solusi:
-- - Tambah FK users.id -> auth.users(id)
-- - Hapus role dari users (gunakan profiles.role sebagai single source of truth)
-- - Buat view untuk gabungan data
-- =============================================================================

-- 1. CEK DATA YANG ADA SEKARANG
-- Lihat apakah ada user di 'users' yang tidak ada di 'profiles'
SELECT 
  u.id,
  u.email,
  u.name,
  u.role as users_role,
  p.role as profiles_role,
  p.username,
  CASE 
    WHEN p.id IS NULL THEN '❌ TIDAK ADA DI PROFILES'
    WHEN u.role != p.role THEN '⚠️ ROLE TIDAK SINKRON'
    ELSE '✅ OK'
  END as status
FROM users u
LEFT JOIN profiles p ON p.id = u.id
ORDER BY status DESC, u.email;

-- 2. CEK SEBALIKNYA - Profiles tanpa users
SELECT 
  p.id,
  p.username,
  p.role,
  u.email,
  u.name,
  CASE 
    WHEN u.id IS NULL THEN '❌ TIDAK ADA DI USERS'
    ELSE '✅ OK'
  END as status
FROM profiles p
LEFT JOIN users u ON u.id = p.id
WHERE u.id IS NULL;

-- =============================================================================
-- 3. PERBAIKAN STRUKTUR
-- =============================================================================

-- Step 1: Backup data yang tidak sinkron
CREATE TEMP TABLE temp_users_backup AS
SELECT * FROM users;

CREATE TEMP TABLE temp_profiles_backup AS
SELECT * FROM profiles;

-- Step 2: Sinkronkan data - Insert missing records
-- Insert ke profiles jika ada di users tapi tidak di profiles
INSERT INTO profiles (id, role, username, created_at)
SELECT 
  u.id,
  u.role,
  COALESCE(u.name, split_part(u.email, '@', 1)) as username,
  COALESCE(u.created_at, now())
FROM users u
LEFT JOIN profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- Insert ke users jika ada di profiles tapi tidak di users
INSERT INTO users (id, email, name, role, created_at)
SELECT 
  p.id,
  au.email,
  p.username,
  p.role,
  COALESCE(p.created_at, now())
FROM profiles p
JOIN auth.users au ON au.id = p.id
LEFT JOIN users u ON u.id = p.id
WHERE u.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- Step 3: Sinkronkan role - profiles sebagai master
UPDATE users u
SET role = p.role
FROM profiles p
WHERE u.id = p.id
  AND u.role != p.role;

-- Step 4: Tambahkan Foreign Key users -> auth.users (jika belum ada)
DO $$
BEGIN
  -- Cek apakah FK sudah ada
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'users_id_fkey' 
      AND table_name = 'users'
  ) THEN
    -- Tambah FK
    ALTER TABLE public.users 
    ADD CONSTRAINT users_id_fkey 
    FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    
    RAISE NOTICE '✅ Foreign key users_id_fkey berhasil ditambahkan';
  ELSE
    RAISE NOTICE 'ℹ️ Foreign key users_id_fkey sudah ada';
  END IF;
END $$;

-- Step 5: Hapus kolom role dari users (OPSIONAL - bisa skip jika masih dipakai)
-- Uncomment jika mau hapus duplikasi role
/*
ALTER TABLE users DROP COLUMN IF EXISTS role;
RAISE NOTICE '✅ Kolom role dihapus dari tabel users';
*/

-- =============================================================================
-- 4. BUAT VIEW UNTUK KEMUDAHAN QUERY
-- =============================================================================

-- View gabungan profiles + users
CREATE OR REPLACE VIEW user_profiles AS
SELECT 
  p.id,
  p.username,
  p.role,
  p.created_at as profile_created_at,
  u.email,
  u.name,
  u.specialization,
  u.bio,
  u.social_media,
  u.profile_image_url,
  u.created_at as user_created_at
FROM profiles p
LEFT JOIN users u ON u.id = p.id;

-- Grant access
GRANT SELECT ON user_profiles TO authenticated;
GRANT SELECT ON user_profiles TO anon;

COMMENT ON VIEW user_profiles IS 'Gabungan data dari tabel profiles dan users untuk kemudahan query';

-- =============================================================================
-- 5. VERIFIKASI HASIL
-- =============================================================================

-- Cek data setelah perbaikan
SELECT 
  p.id,
  p.username,
  p.role as profiles_role,
  u.email,
  u.name,
  u.role as users_role,
  CASE 
    WHEN p.role = u.role THEN '✅ SINKRON'
    ELSE '❌ MASIH TIDAK SINKRON'
  END as status
FROM profiles p
JOIN users u ON u.id = p.id
ORDER BY status DESC, p.role;

-- Cek FK
SELECT
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name IN ('users', 'profiles')
  AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name, tc.constraint_name;

-- =============================================================================
-- 6. BUAT TRIGGER AUTO-SYNC (OPSIONAL)
-- =============================================================================

-- Trigger untuk sinkronisasi role otomatis ketika profiles.role berubah
CREATE OR REPLACE FUNCTION sync_user_role()
RETURNS TRIGGER AS $$
BEGIN
  -- Update role di tabel users ketika role di profiles berubah
  UPDATE users 
  SET role = NEW.role 
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger lama jika ada
DROP TRIGGER IF EXISTS sync_user_role_trigger ON profiles;

-- Buat trigger baru
CREATE TRIGGER sync_user_role_trigger
  AFTER INSERT OR UPDATE OF role ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_role();

COMMENT ON FUNCTION sync_user_role() IS 'Auto-sync role dari profiles ke users';

-- =============================================================================
-- SUMMARY
-- =============================================================================
RAISE NOTICE '
=============================================================================
✅ PERBAIKAN SELESAI
=============================================================================
1. Data di profiles dan users sudah disinkronkan
2. Foreign key users.id -> auth.users(id) sudah ditambahkan
3. View user_profiles sudah dibuat untuk kemudahan query
4. Trigger auto-sync role sudah aktif

REKOMENDASI:
- Gunakan profiles.role sebagai single source of truth
- Hapus users.role jika sudah yakin tidak dipakai (uncomment step 5)
- Gunakan view user_profiles untuk query gabungan

TESTING:
- Jalankan query verifikasi (bagian 5) untuk memastikan semua sinkron
- Test login dan registrasi user baru
- Test FCM token update dengan ganti user
=============================================================================
';
