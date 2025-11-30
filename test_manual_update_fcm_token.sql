-- =============================================================================
-- MANUAL TEST: Update FCM Token User ID
-- =============================================================================
-- Test apakah UPDATE user_id berfungsi tanpa masalah

-- 1. Lihat FCM tokens yang ada sekarang
SELECT 
  ft.id,
  ft.user_id,
  p.username,
  p.role,
  u.email,
  ft.platform,
  ft.is_active,
  substring(ft.token, 1, 30) || '...' as token_preview,
  ft.created_at,
  ft.updated_at
FROM fcm_tokens ft
LEFT JOIN profiles p ON p.id = ft.user_id
LEFT JOIN users u ON u.id = ft.user_id
ORDER BY ft.updated_at DESC
LIMIT 5;

-- 2. Lihat semua user yang ada (untuk ambil ID)
SELECT 
  p.id,
  p.username,
  p.role,
  u.email,
  u.name
FROM profiles p
LEFT JOIN users u ON u.id = p.id
WHERE p.role IN ('artist', 'organizer')
ORDER BY p.role, u.email;

-- =============================================================================
-- 3. TEST MANUAL UPDATE
-- =============================================================================
-- INSTRUKSI:
-- 1. Copy user_id dari query 2 (pilih artist dan organizer)
-- 2. Copy token dari query 1 (atau ambil dari HP)
-- 3. Uncomment dan jalankan test di bawah

/*
-- Test A: Update token dari artist ke organizer (simulasi ganti user di HP yang sama)
DO $$
DECLARE
  v_token text := 'PASTE_TOKEN_DARI_QUERY_1'; -- Ganti dengan token real
  v_artist_id uuid := 'PASTE_ARTIST_ID'; -- User ID lama
  v_organizer_id uuid := 'PASTE_ORGANIZER_ID'; -- User ID baru
  v_old_user_id uuid;
  v_result record;
BEGIN
  -- Cek user_id sebelum update
  SELECT user_id INTO v_old_user_id 
  FROM fcm_tokens 
  WHERE token = v_token;
  
  RAISE NOTICE '🔍 Token saat ini milik user: %', v_old_user_id;
  
  -- Lakukan UPDATE
  UPDATE fcm_tokens 
  SET 
    user_id = v_organizer_id,
    is_active = true,
    updated_at = now()
  WHERE token = v_token
  RETURNING * INTO v_result;
  
  IF FOUND THEN
    RAISE NOTICE '✅ UPDATE BERHASIL!';
    RAISE NOTICE '📊 Token ID: %', v_result.id;
    RAISE NOTICE '👤 User lama: %', v_old_user_id;
    RAISE NOTICE '👤 User baru: %', v_result.user_id;
    RAISE NOTICE '📅 Updated at: %', v_result.updated_at;
  ELSE
    RAISE NOTICE '❌ UPDATE GAGAL - Token tidak ditemukan';
  END IF;
END $$;
*/

-- =============================================================================
-- 4. TEST DENGAN SYNTAX SEDERHANA
-- =============================================================================
-- Jika test di atas gagal, coba syntax ini (lebih simple)

/*
-- Ganti dengan data real
UPDATE fcm_tokens 
SET 
  user_id = 'ORGANIZER_USER_ID_HERE'::uuid,
  is_active = true
WHERE token = 'TOKEN_STRING_HERE'
RETURNING 
  id,
  user_id,
  is_active,
  updated_at;
*/

-- =============================================================================
-- 5. VERIFIKASI SETELAH UPDATE
-- =============================================================================
-- Jalankan ini setelah UPDATE berhasil untuk konfirmasi

/*
SELECT 
  ft.id,
  ft.user_id,
  p.username,
  p.role,
  u.email,
  ft.is_active,
  ft.updated_at,
  'Token sekarang milik ' || p.role || ' (' || u.email || ')' as status
FROM fcm_tokens ft
JOIN profiles p ON p.id = ft.user_id
JOIN users u ON u.id = ft.user_id
WHERE ft.token = 'TOKEN_STRING_HERE';
*/

-- =============================================================================
-- 6. TEST RLS POLICIES (jika UPDATE gagal dengan error permission denied)
-- =============================================================================

-- Cek RLS policies
SELECT 
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'fcm_tokens';

-- Jika ada policy yang block UPDATE, temporary disable untuk test
/*
ALTER TABLE fcm_tokens DISABLE ROW LEVEL SECURITY;
-- Jalankan UPDATE test lagi
-- Lalu enable kembali:
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
*/
