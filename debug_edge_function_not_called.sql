-- Debug: Kenapa Edge Function tidak terpanggil?

-- 1. Cek apakah fungsi helper Edge Function ada
SELECT 
  proname as function_name,
  pronargs as num_arguments,
  proargnames as argument_names,
  pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname = 'send_push_notification_via_edge_function';

-- Jika TIDAK ADA HASIL, berarti fungsi belum dibuat!

-- 2. Cek trigger untuk artwork status
SELECT 
  tgname as trigger_name,
  tgenabled as enabled,
  pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger 
WHERE tgname = 'artwork_status_notification_trigger';

-- 3. Cek isi fungsi notify_artwork_status_change
SELECT pg_get_functiondef(oid) 
FROM pg_proc 
WHERE proname = 'notify_artwork_status_change';

-- 4. Cek recent notifications (apakah in-app notification terinsert?)
SELECT 
  id,
  user_id,
  type,
  title,
  message,
  created_at
FROM notifications
WHERE type IN ('artwork_approved', 'artwork_rejected')
ORDER BY created_at DESC
LIMIT 5;

-- 5. Test manual call Edge Function helper
-- GANTI <user_id> dengan user artist: 21c3ca03-9044-48fc-a50c-2360c2d3542a
DO $$
BEGIN
  PERFORM send_push_notification_via_edge_function(
    '21c3ca03-9044-48fc-a50c-2360c2d3542a',
    'Test Push Notification 🔔',
    'Ini test dari SQL manual',
    '{"type": "test", "source": "sql"}'::jsonb
  );
  
  RAISE NOTICE '✅ Fungsi dipanggil successfully!';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '❌ Error calling function: %', SQLERRM;
END $$;

-- 6. Cek extension pg_net (required untuk HTTP calls)
SELECT extname, extversion 
FROM pg_extension 
WHERE extname = 'pg_net';

-- Jika TIDAK ADA, install:
-- CREATE EXTENSION IF NOT EXISTS pg_net;
