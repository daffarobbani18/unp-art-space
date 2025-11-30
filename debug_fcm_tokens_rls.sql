-- Debug: Cek RLS policies dan test UPDATE fcm_tokens
-- Untuk memastikan tidak ada blocker pada UPDATE user_id

-- 1. Cek RLS policies untuk fcm_tokens
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'fcm_tokens'
ORDER BY policyname;

-- 2. Cek apakah RLS enabled
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'fcm_tokens';

-- 3. Cek struktur lengkap tabel fcm_tokens
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'fcm_tokens'
ORDER BY ordinal_position;

-- 4. Cek constraint foreign key
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name='fcm_tokens';

-- 5. Test manual UPDATE token untuk ganti user_id
-- PENTING: Ganti dengan data real dari query sebelumnya
/*
-- Contoh: Ganti user_id token tertentu
UPDATE fcm_tokens 
SET 
  user_id = 'NEW_USER_ID_HERE'::uuid,
  updated_at = now()
WHERE token = 'TOKEN_STRING_HERE'
RETURNING *;
*/

-- 6. Cek apakah ada trigger yang bisa interfere dengan UPDATE
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE event_object_table = 'fcm_tokens'
ORDER BY trigger_name;
