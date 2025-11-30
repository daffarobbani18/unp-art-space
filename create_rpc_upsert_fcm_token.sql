-- =============================================================================
-- RPC FUNCTION: Upsert FCM Token dengan SECURITY DEFINER (Bypass RLS)
-- =============================================================================
-- Fungsi ini akan bypass RLS policies dan memastikan token ownership
-- dapat di-transfer antar user di device yang sama

CREATE OR REPLACE FUNCTION upsert_fcm_token(
  p_token text,
  p_user_id uuid,
  p_platform text DEFAULT 'android',
  p_device_id text DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER -- PENTING: Bypass RLS, jalan dengan hak akses function owner
SET search_path = public
AS $$
DECLARE
  v_result json;
  v_operation text;
  v_token_id uuid;
BEGIN
  -- Log untuk debugging
  RAISE NOTICE '🔧 upsert_fcm_token called';
  RAISE NOTICE '  Token (30 chars): %', substring(p_token, 1, 30);
  RAISE NOTICE '  User ID: %', p_user_id;
  RAISE NOTICE '  Platform: %', p_platform;
  
  -- Step 1: Nonaktifkan semua token lama user ini (multi-device support)
  UPDATE fcm_tokens 
  SET is_active = false
  WHERE user_id = p_user_id 
    AND token != p_token
    AND is_active = true;
  
  RAISE NOTICE '  ✅ Deactivated % old tokens', FOUND;
  
  -- Step 2: Upsert token - INSERT atau UPDATE jika sudah ada
  INSERT INTO fcm_tokens (
    user_id,
    token,
    platform,
    device_id,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    p_user_id,
    p_token,
    p_platform,
    p_device_id,
    true,
    now(),
    now()
  )
  ON CONFLICT (token) 
  DO UPDATE SET
    user_id = EXCLUDED.user_id,        -- Transfer ownership ke user baru
    platform = EXCLUDED.platform,
    device_id = EXCLUDED.device_id,
    is_active = true,
    updated_at = now()
  RETURNING id, (xmax = 0) AS inserted INTO v_token_id, v_operation;
  
  -- v_operation akan true jika INSERT, false jika UPDATE
  IF v_operation THEN
    RAISE NOTICE '  ✅ Token INSERTED (new token)';
  ELSE
    RAISE NOTICE '  ✅ Token UPDATED (ownership transferred)';
  END IF;
  
  -- Return hasil
  SELECT json_build_object(
    'success', true,
    'operation', CASE WHEN v_operation THEN 'insert' ELSE 'update' END,
    'token_id', v_token_id,
    'user_id', p_user_id,
    'message', CASE 
      WHEN v_operation THEN 'FCM token saved successfully'
      ELSE 'FCM token ownership transferred'
    END
  ) INTO v_result;
  
  RETURN v_result;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Return error sebagai JSON
    RAISE NOTICE '  ❌ Error: %', SQLERRM;
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM,
      'detail', SQLSTATE
    );
END;
$$;

-- Grant execute ke authenticated users
GRANT EXECUTE ON FUNCTION upsert_fcm_token(text, uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_fcm_token(text, uuid, text, text) TO anon;

-- Comment
COMMENT ON FUNCTION upsert_fcm_token IS 
'Upsert FCM token dengan SECURITY DEFINER untuk bypass RLS. 
Otomatis transfer ownership token ketika user berbeda login di device yang sama.';

-- =============================================================================
-- TEST FUNCTION
-- =============================================================================

-- Test 1: Insert token baru
SELECT upsert_fcm_token(
  'test_token_' || gen_random_uuid()::text,
  '21c3ca03-9044-48fc-a50c-2360c2d3542a'::uuid, -- Ganti dengan user_id real
  'android',
  'test_device_123'
);

-- Test 2: Update token existing (transfer ownership)
-- Jalankan dengan user_id berbeda untuk simulasi ganti user
/*
SELECT upsert_fcm_token(
  'TOKEN_YANG_SUDAH_ADA',
  'USER_ID_BARU'::uuid,
  'android',
  'test_device_123'
);
*/

-- =============================================================================
-- VERIFY
-- =============================================================================

-- Cek apakah function sudah dibuat
SELECT 
  proname as function_name,
  prosecdef as is_security_definer,
  CASE 
    WHEN prosecdef THEN '✅ SECURITY DEFINER (Bypass RLS)'
    ELSE '❌ NOT SECURITY DEFINER'
  END as security_status
FROM pg_proc 
WHERE proname = 'upsert_fcm_token';

-- Cek permissions
SELECT 
  routine_name,
  routine_type,
  security_type,
  CASE 
    WHEN security_type = 'DEFINER' THEN '✅ Dapat bypass RLS'
    ELSE '⚠️ Tidak bypass RLS'
  END as status
FROM information_schema.routines
WHERE routine_name = 'upsert_fcm_token'
  AND routine_schema = 'public';

-- =============================================================================
-- CLEANUP (Jika perlu hapus function)
-- =============================================================================
/*
DROP FUNCTION IF EXISTS upsert_fcm_token(text, uuid, text, text);
*/
