-- FIX: Setup Push Notification Edge Function Call
-- Masalah: Edge function tidak dipanggil karena URL tidak di-set dan pg_net mungkin tidak tersedia

-- ============================================
-- CARA 1: SKIP (Permission Denied)
-- ============================================
-- ALTER DATABASE tidak bisa dijalankan, jadi langsung pakai CARA 2

-- ============================================
-- CARA 2: Hardcode URL (SIMPLE & WORKS!)
-- ============================================
-- PENTING: Ganti YOUR_SERVICE_ROLE_KEY dengan key dari:
-- https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/settings/api

-- Recreate fungsi dengan URL hardcoded
CREATE OR REPLACE FUNCTION send_push_notification_via_edge_function(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
DECLARE
  v_edge_function_url text := 'https://vepmvxiddwmpetxfdwjn.supabase.co/functions/v1/send-push-notification';
  v_service_role_key text := 'YOUR_SERVICE_ROLE_KEY'; -- GANTI dengan key dari Supabase Dashboard!
  v_response_id bigint;
BEGIN
  RAISE NOTICE '📤 Sending push notification to user: %', p_user_id;
  RAISE NOTICE '📋 Title: %', p_title;
  RAISE NOTICE '📋 Body: %', p_body;
  
  -- Call Edge Function using pg_net
  SELECT INTO v_response_id
    net.http_post(
      url := v_edge_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || v_service_role_key
      ),
      body := jsonb_build_object(
        'userId', p_user_id::text,
        'title', p_title,
        'body', p_body,
        'data', p_data
      )
    );
  
  RAISE NOTICE '✅ Push notification queued with request ID: %', v_response_id;
    
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ Error sending push notification: %', SQLERRM;
    RAISE NOTICE 'Detail: %', SQLSTATE;
    -- Don't fail main transaction
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TEST FUNGSI
-- ============================================

-- Test call fungsi
DO $$
BEGIN
  PERFORM send_push_notification_via_edge_function(
    '21c3ca03-9044-48fc-a50c-2360c2d3542a'::uuid,
    'Test Push Notification 🔔',
    'Ini adalah test push notification dari database',
    '{"type": "test", "source": "manual_sql"}'::jsonb
  );
  
  RAISE NOTICE '✅ Test completed - Check Edge Function logs and device!';
END $$;

-- ============================================
-- VERIFY TRIGGERS MASIH AKTIF
-- ============================================

-- Cek trigger artwork
SELECT 
  tgname,
  tgenabled,
  pg_get_triggerdef(oid) as definition
FROM pg_trigger 
WHERE tgname = 'artwork_status_notification_trigger';

-- Jika trigger tidak ada atau disabled, recreate:
/*
DROP TRIGGER IF EXISTS artwork_status_notification_trigger ON artworks;

CREATE TRIGGER artwork_status_notification_trigger
  AFTER UPDATE OF status ON artworks
  FOR EACH ROW
  EXECUTE FUNCTION notify_artwork_status_change();
*/

-- ============================================
-- NOTES
-- ============================================

-- 1. PENTING: Ganti service_role_key dengan key dari Supabase Dashboard!
-- 2. Extension pg_net harus sudah terinstall (biasanya sudah ada di Supabase)
-- 3. Edge Function 'send-push-notification' harus sudah deployed
-- 4. Cek logs Edge Function di: https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/functions/send-push-notification/logs
-- 5. Perhatikan RAISE NOTICE di logs database untuk debug
