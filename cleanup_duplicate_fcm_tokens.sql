-- =============================================================================
-- CLEANUP: Hapus token duplikat dan nonaktifkan token lama
-- =============================================================================
-- Jalankan ini sekali untuk membersihkan data yang sudah terlanjur duplikat

BEGIN;

-- Step 1: Nonaktifkan semua token lama (keep hanya yang terbaru per token string)
UPDATE fcm_tokens
SET is_active = false
WHERE id NOT IN (
  SELECT DISTINCT ON (token) id
  FROM fcm_tokens
  ORDER BY token, created_at DESC
);

-- Step 2: Hapus token duplikat (keep hanya yang terbaru)
DELETE FROM fcm_tokens
WHERE id NOT IN (
  SELECT DISTINCT ON (token) id
  FROM fcm_tokens
  ORDER BY token, created_at DESC
);

-- Step 3: Verify hasil
SELECT 
  COUNT(*) as total_tokens,
  COUNT(DISTINCT token) as unique_tokens,
  COUNT(CASE WHEN is_active THEN 1 END) as active_tokens
FROM fcm_tokens;

COMMIT;

-- =============================================================================
-- CHECK: Lihat token yang tersisa
-- =============================================================================
SELECT 
  ft.id,
  ft.user_id,
  p.role,
  p.username,
  LEFT(ft.token, 30) as token_preview,
  ft.is_active,
  ft.created_at,
  ft.updated_at
FROM fcm_tokens ft
JOIN profiles p ON p.id = ft.user_id
ORDER BY ft.created_at DESC;
