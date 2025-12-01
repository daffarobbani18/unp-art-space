-- =============================================================================
-- DATABASE TRIGGER: Auto AI Detection on Artwork Upload
-- =============================================================================
-- Purpose: Automatically call detect-ai Edge Function after artwork INSERT
-- Uses: pg_net extension for HTTP requests (same as push notification)

BEGIN;

-- =============================================================================
-- STEP 1: Ensure pg_net extension is enabled
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net;

-- =============================================================================
-- STEP 2: Create trigger function
-- =============================================================================

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

  -- Skip if artwork is not pending (already processed)
  -- Uncomment if you want to skip non-pending artworks
  /*
  IF NEW.status != 'pending' THEN
    RAISE NOTICE '⏭️ Skipping: Artwork % status is %', NEW.id, NEW.status;
    RETURN NEW;
  END IF;
  */

  -- HARDCODED: Set your project URL and service role key here
  -- Get from: Supabase Dashboard → Settings → API
  v_function_url := 'https://vepmvxiddwmpetxfdwjn.supabase.co/functions/v1/detect-ai';
  v_service_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZlcG12eGlkZHdtcGV0eGZkd2puIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyOTY4MzA1NywiZXhwIjoyMDQ1MjU5MDU3fQ.UOT9eSKSUkkPn-VlhZHKjvwK2HlCQF9-uGW9tOHgpRo';
  
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
-- STEP 3: Create trigger on artworks table
-- =============================================================================

DROP TRIGGER IF EXISTS trigger_artwork_ai_detection ON public.artworks;

CREATE TRIGGER trigger_artwork_ai_detection
  AFTER INSERT ON public.artworks
  FOR EACH ROW
  EXECUTE FUNCTION trigger_ai_detection();

-- Add comment
COMMENT ON TRIGGER trigger_artwork_ai_detection ON public.artworks IS
  'Automatically detect AI-generated content using Sightengine API after artwork upload';

COMMIT;

-- =============================================================================
-- STEP 4: Configuration
-- =============================================================================

-- ✅ Configuration is now HARDCODED in trigger function (see line 48-49)
-- No need to set database parameters (causes permission error)

-- To update URL or key, edit the trigger function directly:
-- 1. Find line: v_function_url := 'https://...'
-- 2. Find line: v_service_key := 'eyJhbGci...'
-- 3. Update values
-- 4. Run: CREATE OR REPLACE FUNCTION trigger_ai_detection() ...

-- =============================================================================
-- VERIFICATION
-- =============================================================================

-- Check if trigger exists
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_artwork_ai_detection';

-- Check if function exists
SELECT 
  proname as function_name,
  prosecdef as is_security_definer
FROM pg_proc
WHERE proname = 'trigger_ai_detection';

-- Check trigger function source (verify hardcoded values)
SELECT 
  pg_get_functiondef(oid) as function_definition
FROM pg_proc
WHERE proname = 'trigger_ai_detection';

-- =============================================================================
-- TESTING
-- =============================================================================

-- Test 1: Insert artwork with media_url (should trigger AI detection)
/*
INSERT INTO public.artworks (
  title,
  description,
  media_url,
  category,
  artist_id,
  artist_name,
  status
) VALUES (
  'Test AI Artwork',
  'Testing AI detection',
  'https://example.com/test-image.jpg',
  'digital',
  '21c3ca03-9044-48fc-a50c-2360c2d3542a',
  'Test Artist',
  'pending'
) RETURNING id, title, media_url;
*/

-- Test 2: Check pg_net logs
/*
SELECT 
  id,
  created,
  status_code,
  content::text
FROM net._http_response
ORDER BY created DESC
LIMIT 5;
*/

-- Test 3: Check artwork AI scores
/*
SELECT 
  id,
  title,
  media_url,
  ai_generated_score,
  is_ai_suspected,
  created_at
FROM public.artworks
ORDER BY created_at DESC
LIMIT 10;
*/

-- =============================================================================
-- DISABLE TRIGGER (if needed)
-- =============================================================================
/*
ALTER TABLE public.artworks 
DISABLE TRIGGER trigger_artwork_ai_detection;
*/

-- =============================================================================
-- ENABLE TRIGGER (if disabled)
-- =============================================================================
/*
ALTER TABLE public.artworks 
ENABLE TRIGGER trigger_artwork_ai_detection;
*/

-- =============================================================================
-- CLEANUP / ROLLBACK
-- =============================================================================
/*
BEGIN;

DROP TRIGGER IF EXISTS trigger_artwork_ai_detection ON public.artworks;
DROP FUNCTION IF EXISTS trigger_ai_detection();

-- Note: Don't drop pg_net if used by other features (push notifications)
-- DROP EXTENSION IF EXISTS pg_net;

COMMIT;
*/
