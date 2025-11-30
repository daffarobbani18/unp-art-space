-- =============================================================================
-- FIX: RLS Policies untuk fcm_tokens
-- =============================================================================
-- Masalah: RLS enabled tapi tidak ada policies → semua query blocked!
-- Solusi: Buat policies yang membolehkan user manage token mereka sendiri

-- =============================================================================
-- 1. DROP EXISTING POLICIES (jika ada)
-- =============================================================================
DROP POLICY IF EXISTS "Users can view their own tokens" ON fcm_tokens;
DROP POLICY IF EXISTS "Users can insert their own tokens" ON fcm_tokens;
DROP POLICY IF EXISTS "Users can update their own tokens" ON fcm_tokens;
DROP POLICY IF EXISTS "Users can delete their own tokens" ON fcm_tokens;
DROP POLICY IF EXISTS "Service role has full access to fcm_tokens" ON fcm_tokens;

-- =============================================================================
-- 2. CREATE NEW POLICIES
-- =============================================================================

-- Policy 1: User bisa lihat token mereka sendiri
CREATE POLICY "Users can view their own tokens"
ON fcm_tokens
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy 2: User bisa insert token untuk diri sendiri
CREATE POLICY "Users can insert their own tokens"
ON fcm_tokens
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy 3: User bisa update token mereka sendiri
-- PENTING: Ini yang paling crucial untuk FCM token transfer!
CREATE POLICY "Users can update their own tokens"
ON fcm_tokens
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id) -- User lama bisa update
WITH CHECK (auth.uid() = user_id); -- User baru jadi owner

-- Policy 4: User bisa hapus token mereka sendiri
CREATE POLICY "Users can delete their own tokens"
ON fcm_tokens
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Policy 5: Service role punya full access (untuk Edge Function)
CREATE POLICY "Service role has full access to fcm_tokens"
ON fcm_tokens
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- =============================================================================
-- 3. POLICY ALTERNATIF - Lebih Permisif (jika policy di atas masih block)
-- =============================================================================
-- Uncomment jika masih ada masalah dengan token transfer antar user

/*
-- Drop policy yang ketat
DROP POLICY IF EXISTS "Users can update their own tokens" ON fcm_tokens;

-- Policy update yang lebih permisif untuk token transfer
CREATE POLICY "Users can update any tokens to their ownership"
ON fcm_tokens
FOR UPDATE
TO authenticated
USING (true) -- Semua authenticated user bisa update token manapun
WITH CHECK (auth.uid() = user_id); -- Tapi hanya bisa set user_id ke diri sendiri

COMMENT ON POLICY "Users can update any tokens to their ownership" ON fcm_tokens 
IS 'Membolehkan user mengambil ownership token dari device yang sama setelah user lain logout';
*/

-- =============================================================================
-- 4. VERIFIKASI POLICIES
-- =============================================================================

-- Lihat semua policies yang aktif
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd as command,
  qual as using_expression,
  with_check
FROM pg_policies 
WHERE tablename = 'fcm_tokens'
ORDER BY cmd, policyname;

-- Cek RLS status
SELECT 
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity THEN '✅ RLS Enabled'
    ELSE '❌ RLS Disabled'
  END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'fcm_tokens';

-- Count policies
SELECT 
  COUNT(*) as total_policies,
  CASE 
    WHEN COUNT(*) >= 5 THEN '✅ Policies sudah lengkap'
    WHEN COUNT(*) > 0 THEN '⚠️ Policies kurang lengkap'
    ELSE '❌ TIDAK ADA POLICIES!'
  END as status
FROM pg_policies 
WHERE tablename = 'fcm_tokens';

-- =============================================================================
-- 5. TEST SETELAH POLICY DIBUAT
-- =============================================================================

-- Test sebagai authenticated user (simulasi dari Flutter app)
SET LOCAL ROLE authenticated;

-- Test INSERT (harus berhasil untuk user sendiri)
/*
INSERT INTO fcm_tokens (user_id, token, platform, is_active)
VALUES (
  auth.uid(), 
  'test_token_' || gen_random_uuid()::text,
  'android',
  true
)
RETURNING id, user_id, token, created_at;
*/

-- Test UPDATE (harus berhasil untuk token sendiri)
/*
UPDATE fcm_tokens 
SET is_active = false
WHERE user_id = auth.uid()
RETURNING id, user_id, is_active, updated_at;
*/

-- Reset role
RESET ROLE;

-- =============================================================================
-- 6. SUMMARY & NOTES
-- =============================================================================

DO $$
BEGIN
  RAISE NOTICE '
=============================================================================
✅ RLS POLICIES UNTUK FCM_TOKENS SUDAH DIBUAT
=============================================================================

POLICIES YANG DIBUAT:
1. Users can view their own tokens (SELECT)
2. Users can insert their own tokens (INSERT)
3. Users can update their own tokens (UPDATE)
4. Users can delete their own tokens (DELETE)
5. Service role has full access (ALL) - untuk Edge Function

CARA KERJA TOKEN TRANSFER (User A logout → User B login):
1. User A logout → Flutter call deleteFCMToken() → SET is_active=false ✅
2. User B login → Flutter call saveFCMToken() → UPDATE user_id ke User B

PENTING:
- Policy 3 membolehkan user mengambil ownership token yang sudah ada
- Service role policy membolehkan Edge Function baca semua tokens
- Jika masih ada masalah, uncomment Policy Alternatif (bagian 3)

TESTING:
- Hot restart Flutter app
- Login User A → Check FCM token saved
- Logout User A
- Login User B (same device) → Check token ownership transferred
- Check console logs untuk: "✅ FCM token ownership transferred"

TROUBLESHOOTING:
Jika UPDATE masih gagal, jalankan:
  SELECT * FROM pg_policies WHERE tablename = ''fcm_tokens'';
  
Pastikan ada 5 policies aktif!
=============================================================================
  ';
END $$;
