-- Quick Check: Apakah FCM token untuk artist@campus.art tersimpan?

-- 1. Cek user artist
SELECT 
  id,
  email,
  raw_user_meta_data->>'role' as role,
  created_at
FROM auth.users 
WHERE email = 'artist@campus.art';

-- Expected: 21c3ca03-9044-48fc-a50c-2360c2d3542a

-- 2. Cek FCM tokens untuk user ini
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
WHERE user_id = '21c3ca03-9044-48fc-a50c-2360c2d3542a'
ORDER BY created_at DESC;

-- 3. Cek semua FCM tokens (untuk perbandingan)
SELECT 
  ft.id,
  ft.user_id,
  u.email,
  ft.platform,
  ft.is_active,
  ft.created_at
FROM fcm_tokens ft
LEFT JOIN auth.users u ON ft.user_id = u.id
ORDER BY ft.created_at DESC
LIMIT 10;

-- 4. Cek RLS policies
SELECT 
  policyname,
  cmd as command,
  roles,
  qual as using_condition,
  with_check as with_check_condition
FROM pg_policies 
WHERE tablename = 'fcm_tokens'
ORDER BY cmd;

-- 5. Test INSERT manual sebagai authenticated user
-- (Simulasi apa yang Flutter coba lakukan)
DO $$
DECLARE
  v_user_id uuid := '21c3ca03-9044-48fc-a50c-2360c2d3542a';
  v_token text := 'test_manual_insert_' || gen_random_uuid()::text;
  v_result uuid;
BEGIN
  -- Set auth context (simulate authenticated request)
  PERFORM set_config('request.jwt.claim.sub', v_user_id::text, true);
  
  -- Try INSERT
  INSERT INTO fcm_tokens (user_id, token, platform, is_active)
  VALUES (v_user_id, v_token, 'android', true)
  RETURNING id INTO v_result;
  
  RAISE NOTICE '✅ Manual INSERT berhasil! Token ID: %', v_result;
  
  -- Cleanup
  DELETE FROM fcm_tokens WHERE id = v_result;
  RAISE NOTICE '🗑️ Test token cleaned up';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '❌ Manual INSERT GAGAL!';
  RAISE NOTICE 'Error: %', SQLERRM;
  RAISE NOTICE 'Detail: %', SQLSTATE;
END $$;

-- 6. Jika INSERT gagal, fix RLS policy
-- Uncomment jika perlu:
/*
-- Drop policy lama
DROP POLICY IF EXISTS "Users can insert their own tokens" ON fcm_tokens;

-- Buat policy baru yang lebih permissive
CREATE POLICY "Users can insert their own tokens"
  ON fcm_tokens
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Verify
SELECT 'Policy created successfully' as status;
*/
