-- Quick Check: Apakah sistem push notification sudah lengkap?

-- 1. Cek fungsi Edge Function helper
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc WHERE proname = 'send_push_notification_via_edge_function'
    ) THEN '✅ Fungsi send_push_notification_via_edge_function ADA'
    ELSE '❌ Fungsi send_push_notification_via_edge_function TIDAK ADA - HARUS DIBUAT!'
  END as status;

-- 2. Jika fungsi TIDAK ADA, jalankan ini:
-- (Uncomment jika diperlukan)

/*
CREATE OR REPLACE FUNCTION send_push_notification_via_edge_function(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
DECLARE
  v_supabase_url text;
  v_service_role_key text;
BEGIN
  -- Ambil URL dan key dari settings (set via Supabase Dashboard atau ALTER DATABASE)
  -- Atau hardcode untuk testing (TIDAK AMAN untuk production)
  v_supabase_url := 'https://vepmvxiddwmpetxfdwjn.supabase.co';
  v_service_role_key := current_setting('app.service_role_key', true);
  
  -- Jika tidak ada setting, skip (tapi log error)
  IF v_service_role_key IS NULL THEN
    RAISE WARNING 'Service role key not configured. Cannot send push notification.';
    RETURN;
  END IF;
  
  -- Call Edge Function via HTTP
  PERFORM net.http_post(
    url := v_supabase_url || '/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_role_key
    ),
    body := jsonb_build_object(
      'userId', p_user_id,
      'title', p_title,
      'body', p_body,
      'data', p_data
    )
  );
  
  RAISE NOTICE 'Push notification queued for user: %', p_user_id;
EXCEPTION
  WHEN OTHERS THEN
    -- Jangan break main transaction jika Edge Function call gagal
    RAISE WARNING 'Error calling Edge Function: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
*/
