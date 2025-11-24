-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.announcements (
  id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  tittle text NOT NULL,
  content text NOT NULL,
  CONSTRAINT announcements_pkey PRIMARY KEY (id)
);
CREATE TABLE public.artworks (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  title text,
  description text,
  media_url text,
  external_link text,
  category text,
  status text DEFAULT '''pending'''::text,
  artist_id uuid,
  likes_count bigint DEFAULT '0'::bigint,
  artist_name text,
  artwork_type text DEFAULT '''image'''::text,
  thumbnail_url text,
  CONSTRAINT artworks_pkey PRIMARY KEY (id),
  CONSTRAINT artworks_artist_id_fkey1 FOREIGN KEY (artist_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.categories (
  id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  name text NOT NULL,
  CONSTRAINT categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamp with time zone DEFAULT now(),
  user_id uuid NOT NULL,
  artwork_id bigint NOT NULL,
  content text NOT NULL,
  CONSTRAINT comments_pkey PRIMARY KEY (id),
  CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT comments_artwork_id_fkey FOREIGN KEY (artwork_id) REFERENCES public.artworks(id)
);
CREATE TABLE public.event_submissions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamp with time zone DEFAULT now(),
  event_id uuid NOT NULL,
  artwork_id bigint NOT NULL,
  artist_id uuid NOT NULL,
  status text DEFAULT 'pending'::text,
  curator_note text,
  CONSTRAINT event_submissions_pkey PRIMARY KEY (id),
  CONSTRAINT event_submissions_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id),
  CONSTRAINT event_submissions_artwork_id_fkey FOREIGN KEY (artwork_id) REFERENCES public.artworks(id),
  CONSTRAINT event_submissions_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  title text NOT NULL,
  content text,
  event_date timestamp with time zone,
  location text,
  image_url text,
  status text NOT NULL DEFAULT '''pending'''::text,
  artist_id uuid DEFAULT gen_random_uuid(),
  rejection_reason text,
  organizer_id uuid,
  CONSTRAINT events_pkey PRIMARY KEY (id),
  CONSTRAINT events_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES public.profiles(id),
  CONSTRAINT events_organizer_id_fkey FOREIGN KEY (organizer_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.likes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamp with time zone DEFAULT now(),
  user_id uuid NOT NULL,
  artwork_id bigint NOT NULL,
  CONSTRAINT likes_pkey PRIMARY KEY (id),
  CONSTRAINT likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT likes_artwork_id_fkey FOREIGN KEY (artwork_id) REFERENCES public.artworks(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  role text DEFAULT '''user'''::text CHECK (role = ANY (ARRAY['admin'::text, 'artist'::text, 'viewer'::text, 'organizer'::text])),
  username text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  name text,
  email text UNIQUE,
  role text DEFAULT 'viewer'::text,
  specialization text,
  bio text,
  social_media jsonb,
  profile_image_url text,
  CONSTRAINT users_pkey PRIMARY KEY (id)
);