-- Debug Script: Cek dan Test Push Notification

-- 1. Cek apakah ada FCM tokens yang tersimpan
SELECT 
  'FCM Tokens' as check_type,
  user_id, 
  token, 
  platform, 
  device_id,
  is_active,
  created_at
FROM fcm_tokens
WHERE is_active = true
ORDER BY created_at DESC
LIMIT 5;

-- 2. Cek apakah fungsi send_push_notification_via_edge_function ada
SELECT 
  'Function Exists' as check_type,
  proname as function_name,
  prokind as function_type
FROM pg_proc
WHERE proname = 'send_push_notification_via_edge_function';

-- 3. Cek apakah trigger event_status_notification_trigger aktif
SELECT 
  'Trigger Status' as check_type,
  tgname as trigger_name,
  tgenabled as enabled,
  tgtype as trigger_type
FROM pg_trigger
WHERE tgname = 'event_status_notification_trigger';

-- 4. Cek events yang bisa ditest (pending events)
SELECT 
  'Pending Events' as check_type,
  id,
  title,
  status,
  organizer_id,
  created_at
FROM events
WHERE status = 'pending'
ORDER BY created_at DESC
LIMIT 3;

-- 5. Test manual insert notification (ganti <user_id> dengan ID user yang punya FCM token)
-- Uncomment dan ganti <user_id> untuk test:
/*
DO $$
DECLARE
  v_user_id uuid := '<user_id>'; -- GANTI INI dengan user_id dari query FCM tokens di atas
  v_test_data jsonb := jsonb_build_object('type', 'test', 'message', 'Test notification');
BEGIN
  -- Test panggil fungsi Edge Function
  PERFORM send_push_notification_via_edge_function(
    v_user_id,
    'Test Notification 🔔',
    'Ini adalah test push notification dari Supabase',
    v_test_data
  );
  
  RAISE NOTICE '✅ Test notification sent to user: %', v_user_id;
END $$;
*/

-- 6. Cek recent notifications
SELECT 
  'Recent Notifications' as check_type,
  id,
  user_id,
  type,
  title,
  message,
  created_at,
  is_read
FROM notifications
ORDER BY created_at DESC
LIMIT 5;
