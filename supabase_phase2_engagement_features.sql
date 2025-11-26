-- ============================================
-- Phase 2.1: Engagement Features - Database Schema
-- Tables: artist_follows, artwork views/shares tracking
-- ============================================

-- 1. Artist Follow System
-- Tracks who follows which artist
CREATE TABLE IF NOT EXISTS public.artist_follows (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  follower_id uuid NOT NULL,
  artist_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT artist_follows_pkey PRIMARY KEY (id),
  CONSTRAINT artist_follows_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT artist_follows_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT artist_follows_unique UNIQUE (follower_id, artist_id),
  CONSTRAINT artist_follows_no_self_follow CHECK (follower_id != artist_id)
);

-- Index for fast follower lookups
CREATE INDEX IF NOT EXISTS idx_artist_follows_follower ON public.artist_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_artist_follows_artist ON public.artist_follows(artist_id);

-- 2. Add view counter to artworks table
-- Alternative: Can use separate table for detailed tracking
ALTER TABLE public.artworks 
ADD COLUMN IF NOT EXISTS views_count bigint DEFAULT 0;

-- 3. Add share counter to artworks table
ALTER TABLE public.artworks 
ADD COLUMN IF NOT EXISTS shares_count bigint DEFAULT 0;

-- ============================================
-- Optional: Detailed tracking tables (if needed)
-- ============================================

-- Artwork Views (detailed tracking with viewer info)
-- Uncomment if you want detailed analytics per view
/*
CREATE TABLE IF NOT EXISTS public.artwork_views (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  artwork_id bigint NOT NULL,
  viewer_id uuid, -- nullable for guest users
  viewed_at timestamp with time zone DEFAULT now(),
  CONSTRAINT artwork_views_pkey PRIMARY KEY (id),
  CONSTRAINT artwork_views_artwork_id_fkey FOREIGN KEY (artwork_id) REFERENCES public.artworks(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_artwork_views_artwork ON public.artwork_views(artwork_id);
CREATE INDEX IF NOT EXISTS idx_artwork_views_viewer ON public.artwork_views(viewer_id);
*/

-- Artwork Shares (detailed tracking with sharer info)
-- Uncomment if you want detailed analytics per share
/*
CREATE TABLE IF NOT EXISTS public.artwork_shares (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  artwork_id bigint NOT NULL,
  sharer_id uuid, -- nullable for guest users
  share_platform text, -- 'link', 'qr', 'social', etc
  shared_at timestamp with time zone DEFAULT now(),
  CONSTRAINT artwork_shares_pkey PRIMARY KEY (id),
  CONSTRAINT artwork_shares_artwork_id_fkey FOREIGN KEY (artwork_id) REFERENCES public.artworks(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_artwork_shares_artwork ON public.artwork_shares(artwork_id);
*/

-- ============================================
-- RLS Policies for Security
-- ============================================

-- Enable RLS on artist_follows
ALTER TABLE public.artist_follows ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view follows
CREATE POLICY "Anyone can view follows" ON public.artist_follows
  FOR SELECT
  USING (true);

-- Policy: Users can follow artists
CREATE POLICY "Users can follow artists" ON public.artist_follows
  FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

-- Policy: Users can unfollow (delete their own follows)
CREATE POLICY "Users can unfollow" ON public.artist_follows
  FOR DELETE
  USING (auth.uid() = follower_id);

-- ============================================
-- Helper Functions
-- ============================================

-- Function: Get follower count for an artist
CREATE OR REPLACE FUNCTION get_follower_count(artist_uuid uuid)
RETURNS bigint AS $$
  SELECT COUNT(*)::bigint FROM public.artist_follows WHERE artist_id = artist_uuid;
$$ LANGUAGE SQL STABLE;

-- Function: Get following count for a user
CREATE OR REPLACE FUNCTION get_following_count(user_uuid uuid)
RETURNS bigint AS $$
  SELECT COUNT(*)::bigint FROM public.artist_follows WHERE follower_id = user_uuid;
$$ LANGUAGE SQL STABLE;

-- Function: Check if user follows artist
CREATE OR REPLACE FUNCTION is_following(user_uuid uuid, artist_uuid uuid)
RETURNS boolean AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.artist_follows 
    WHERE follower_id = user_uuid AND artist_id = artist_uuid
  );
$$ LANGUAGE SQL STABLE;

-- ============================================
-- End of Migration
-- ============================================

-- Notes:
-- 1. Run this in Supabase SQL Editor
-- 2. views_count and shares_count will be updated via app logic
-- 3. RLS policies ensure data security
-- 4. Indexes improve query performance
