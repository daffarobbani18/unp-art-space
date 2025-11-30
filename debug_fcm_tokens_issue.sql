-- Debug: Check RLS Policies untuk fcm_tokens

-- 1. Cek apakah RLS aktif
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'fcm_tokens';

-- 2. Cek semua policies untuk fcm_tokens
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd as command,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies 
WHERE tablename = 'fcm_tokens';

-- 3. Test INSERT dengan user saat ini (untuk debug)
-- Ganti '<token_test>' dengan token test
DO $$
BEGIN
  -- Cek auth.uid() ada
  IF auth.uid() IS NULL THEN
    RAISE NOTICE '❌ auth.uid() is NULL - User tidak authenticated!';
  ELSE
    RAISE NOTICE '✅ auth.uid() = %', auth.uid();
    
    -- Test INSERT
    BEGIN
      INSERT INTO fcm_tokens (user_id, token, platform, is_active)
      VALUES (auth.uid(), 'test_token_' || gen_random_uuid()::text, 'android', true);
      
      RAISE NOTICE '✅ Test INSERT berhasil!';
      
      -- Cleanup test
      DELETE FROM fcm_tokens WHERE token LIKE 'test_token_%';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE '❌ Test INSERT gagal: %', SQLERRM;
    END;
  END IF;
END $$;

-- 4. Cek apakah ada fcm_tokens untuk user tertentu
-- Ganti '<user_id>' dengan ID user artist
SELECT 
  id,
  user_id,
  token,
  platform,
  device_id,
  is_active,
  created_at,
  updated_at
FROM fcm_tokens 
WHERE user_id = '<user_id>'  -- GANTI INI!
ORDER BY created_at DESC;

-- 5. Cek semua fcm_tokens (untuk debug)
SELECT 
  ft.id,
  ft.user_id,
  p.email,
  p.role,
  ft.token,
  ft.platform,
  ft.is_active,
  ft.created_at
FROM fcm_tokens ft
LEFT JOIN profiles p ON ft.user_id = p.id
ORDER BY ft.created_at DESC
LIMIT 10;
