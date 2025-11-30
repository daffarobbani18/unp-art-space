-- =============================================================================
-- MIGRATION: Add AI Detection Columns to Artworks Table
-- =============================================================================
-- Date: 2025-11-30
-- Purpose: Support AI Art Detection feature using Sightengine API

BEGIN;

-- Add columns for AI detection
ALTER TABLE public.artworks
  ADD COLUMN IF NOT EXISTS ai_generated_score float4,
  ADD COLUMN IF NOT EXISTS is_ai_suspected boolean DEFAULT false NOT NULL;

-- Add index for faster queries on AI suspected artworks
CREATE INDEX IF NOT EXISTS idx_artworks_ai_suspected 
  ON public.artworks(is_ai_suspected) 
  WHERE is_ai_suspected = true;

-- Add index for score queries
CREATE INDEX IF NOT EXISTS idx_artworks_ai_score 
  ON public.artworks(ai_generated_score) 
  WHERE ai_generated_score IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.artworks.ai_generated_score IS 
  'AI-generated probability score from Sightengine API (0.0 - 1.0). NULL means not yet analyzed.';

COMMENT ON COLUMN public.artworks.is_ai_suspected IS 
  'Flag indicating if artwork is suspected to be AI-generated (score > 0.8). Default false.';

COMMIT;

-- =============================================================================
-- VERIFICATION
-- =============================================================================

-- Check if columns were added successfully
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'artworks'
  AND column_name IN ('ai_generated_score', 'is_ai_suspected')
ORDER BY column_name;

-- Check indexes
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'artworks'
  AND indexname LIKE '%ai%'
ORDER BY indexname;

-- =============================================================================
-- SAMPLE QUERIES (for testing)
-- =============================================================================

-- Get all AI suspected artworks
/*
SELECT 
  id,
  title,
  artist_name,
  ai_generated_score,
  is_ai_suspected,
  status,
  created_at
FROM public.artworks
WHERE is_ai_suspected = true
ORDER BY ai_generated_score DESC;
*/

-- Get artworks with high AI score (>0.8) but not flagged yet
/*
SELECT 
  id,
  title,
  ai_generated_score,
  is_ai_suspected
FROM public.artworks
WHERE ai_generated_score > 0.8
  AND is_ai_suspected = false;
*/

-- =============================================================================
-- ROLLBACK (if needed)
-- =============================================================================
/*
BEGIN;

DROP INDEX IF EXISTS idx_artworks_ai_suspected;
DROP INDEX IF EXISTS idx_artworks_ai_score;

ALTER TABLE public.artworks
  DROP COLUMN IF EXISTS ai_generated_score,
  DROP COLUMN IF EXISTS is_ai_suspected;

COMMIT;
*/
