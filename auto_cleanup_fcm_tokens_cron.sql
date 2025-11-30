-- =============================================================================
-- CRON JOB: Auto-cleanup FCM tokens lama (Optional)
-- =============================================================================
-- Jalankan otomatis setiap hari untuk hapus token inactive > 7 hari
-- Hanya perlu jika ingin cleanup SEMUA user, bukan hanya saat login

-- Enable pg_cron extension (jika belum)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule cleanup job (setiap hari jam 2 pagi)
SELECT cron.schedule(
  'cleanup-inactive-fcm-tokens',  -- Job name
  '0 2 * * *',                    -- Cron schedule (2 AM daily)
  $$
    DELETE FROM fcm_tokens
    WHERE is_active = false
      AND updated_at < now() - INTERVAL '7 days';
  $$
);

-- =============================================================================
-- VERIFY CRON JOB
-- =============================================================================
SELECT * FROM cron.job;

-- =============================================================================
-- MANUAL CLEANUP (Alternative)
-- =============================================================================
-- Jalankan manual jika tidak mau pakai cron job

DELETE FROM fcm_tokens
WHERE is_active = false
  AND updated_at < now() - INTERVAL '7 days';

-- Check berapa baris yang dihapus
SELECT 
  COUNT(*) as total_deleted
FROM fcm_tokens
WHERE is_active = false
  AND updated_at < now() - INTERVAL '7 days';

-- =============================================================================
-- UNSCHEDULE CRON JOB (Jika ingin disable)
-- =============================================================================
/*
SELECT cron.unschedule('cleanup-inactive-fcm-tokens');
*/
