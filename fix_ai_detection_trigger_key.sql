-- =============================================================================
-- FIX: Update Service Role Key di Trigger Function
-- =============================================================================
-- Gunakan key yang SAMA seperti di PowerShell test (yang berhasil!)

CREATE OR REPLACE FUNCTION trigger_ai_detection()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_request_id bigint;
  v_function_url text;
  v_service_key text;
  v_payload jsonb;
BEGIN
  -- Log trigger execution
  RAISE NOTICE '🤖 AI Detection triggered for artwork ID: %', NEW.id;
  RAISE NOTICE '🖼️ Media URL: %', NEW.media_url;

  -- Only process if media_url exists (image/video artwork)
  IF NEW.media_url IS NULL OR NEW.media_url = '' THEN
    RAISE NOTICE '⏭️ Skipping: No media_url for artwork %', NEW.id;
    RETURN NEW;
  END IF;

  -- HARDCODED: GANTI KEY DENGAN KEY YANG BERHASIL DI POWERSHELL!
  -- Get from: Supabase Dashboard → Settings → API → service_role (secret)
  v_function_url := 'https://vepmvxiddwmpetxfdwjn.supabase.co/functions/v1/detect-ai';
  v_service_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZlcG12eGlkZHdtcGV0eGZkd2puIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQyMzkyMCwiZXhwIjoyMDc0OTk5OTIwfQ.lTBWwtQ97jUFZ-OG2f0SfPr-ptoXy-fMWjvX6JxRdyw';
  
  RAISE NOTICE '🔧 Function URL: %', v_function_url;
  
  IF v_service_key IS NULL OR v_service_key = '' THEN
    RAISE NOTICE '❌ ERROR: service_role_key not set in trigger function!';
    RAISE NOTICE '💡 Edit this SQL file and set v_service_key variable';
    RETURN NEW;
  END IF;

  -- Build payload (database webhook format)
  v_payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'artworks',
    'schema', 'public',
    'record', jsonb_build_object(
      'id', NEW.id,
      'media_url', NEW.media_url,
      'title', NEW.title,
      'artist_id', NEW.artist_id,
      'artist_name', NEW.artist_name
    ),
    'old_record', NULL
  );

  RAISE NOTICE '📦 Payload: %', v_payload;

  -- Make HTTP POST request to Edge Function
  SELECT net.http_post(
    url := v_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_service_key
    ),
    body := v_payload
  ) INTO v_request_id;

  RAISE NOTICE '✅ HTTP request sent, request_id: %', v_request_id;

  RETURN NEW;

EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the INSERT
    RAISE NOTICE '❌ Error in trigger_ai_detection: %', SQLERRM;
    RAISE NOTICE '📋 Detail: %', SQLSTATE;
    RETURN NEW;
END;
$$;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

-- Check if function updated
SELECT 
  proname,
  prosecdef as is_security_definer
FROM pg_proc
WHERE proname = 'trigger_ai_detection';

-- Trigger sudah exist, tidak perlu dibuat lagi
-- Hanya update function-nya saja
