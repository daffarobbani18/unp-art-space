-- =============================================================================
-- DEBUG: Check AI Detection System Status
-- =============================================================================

-- Step 1: Check if trigger exists and enabled
SELECT 
  tgname as trigger_name,
  tgenabled::int as status,
  CASE tgenabled::int
    WHEN 1 THEN '✅ Enabled'
    WHEN 0 THEN '❌ Disabled'
  END as status_text
FROM pg_trigger
WHERE tgname = 'trigger_artwork_ai_detection';

-- Step 2: Check recent artworks (last 10)
SELECT 
  id,
  title,
  LEFT(media_url, 50) as media_url_preview,
  ai_generated_score,
  is_ai_suspected,
  status,
  created_at
FROM public.artworks
ORDER BY created_at DESC
LIMIT 10;

-- Step 3: Check pg_net HTTP logs (trigger execution)
SELECT 
  id,
  created,
  status_code,
  LEFT(content::text, 200) as response_preview
FROM net._http_response
ORDER BY created DESC
LIMIT 10;

-- Step 4: Check if pg_net extension enabled
SELECT 
  extname,
  extversion
FROM pg_extension
WHERE extname = 'pg_net';

-- Step 5: Test trigger manually (insert test artwork)
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
  'Manual Test - AI Detection',
  'Testing trigger execution',
  'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe',
  'digital',
  '21c3ca03-9044-48fc-a50c-2360c2d3542a',
  'Test Artist',
  'pending'
) RETURNING id, title, media_url;
*/
