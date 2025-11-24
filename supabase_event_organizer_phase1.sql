-- ===================================================================
-- FASE 1: EVENT ORGANIZER FEATURE - DATABASE SETUP
-- ===================================================================
-- File ini berisi query SQL untuk setup database Event Organizer
-- Jalankan query ini di Supabase SQL Editor
-- ===================================================================

-- 1. UPDATE ROLE CONSTRAINT (Menambahkan 'organizer')
-- ===================================================================
-- Hapus constraint lama dan buat baru dengan role 'organizer'
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check 
CHECK (role IN ('admin', 'artist', 'viewer', 'organizer'));

-- 2. UPDATE TABEL EVENTS (Menambahkan Organizer ID)
-- ===================================================================
-- Kolom untuk track siapa organizer yang membuat event
ALTER TABLE public.events 
ADD COLUMN IF NOT EXISTS organizer_id uuid REFERENCES public.profiles(id);

-- 3. BUAT TABEL EVENT_SUBMISSIONS
-- ===================================================================
-- Tabel untuk menyimpan submission artwork ke event
CREATE TABLE IF NOT EXISTS public.event_submissions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at timestamptz DEFAULT now(),
  event_id uuid REFERENCES public.events(id) ON DELETE CASCADE NOT NULL,
  artwork_id bigint REFERENCES public.artworks(id) ON DELETE CASCADE NOT NULL,
  artist_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  curator_note text,
  reviewed_at timestamptz,
  UNIQUE(event_id, artwork_id) -- Mencegah double submit
);

-- 4. CREATE INDEX untuk Performance
-- ===================================================================
CREATE INDEX IF NOT EXISTS idx_event_submissions_event_id ON public.event_submissions(event_id);
CREATE INDEX IF NOT EXISTS idx_event_submissions_artist_id ON public.event_submissions(artist_id);
CREATE INDEX IF NOT EXISTS idx_event_submissions_status ON public.event_submissions(status);
CREATE INDEX IF NOT EXISTS idx_events_organizer_id ON public.events(organizer_id);

-- 5. ENABLE ROW LEVEL SECURITY
-- ===================================================================
ALTER TABLE public.event_submissions ENABLE ROW LEVEL SECURITY;

-- 6. RLS POLICIES untuk EVENT_SUBMISSIONS
-- ===================================================================

-- Policy A: Organizer boleh melihat semua submisi di event mereka
DROP POLICY IF EXISTS "Organizer view submissions" ON public.event_submissions;
CREATE POLICY "Organizer view submissions" ON public.event_submissions
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.events 
    WHERE events.id = event_submissions.event_id 
    AND events.organizer_id = auth.uid()
  )
);

-- Policy B: Organizer boleh update status submisi
DROP POLICY IF EXISTS "Organizer update submissions" ON public.event_submissions;
CREATE POLICY "Organizer update submissions" ON public.event_submissions
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.events 
    WHERE events.id = event_submissions.event_id 
    AND events.organizer_id = auth.uid()
  )
);

-- Policy C: Artist boleh melihat submisi mereka sendiri
DROP POLICY IF EXISTS "Artist view own submissions" ON public.event_submissions;
CREATE POLICY "Artist view own submissions" ON public.event_submissions
FOR SELECT USING (auth.uid() = artist_id);

-- Policy D: Artist boleh membuat submisi baru
DROP POLICY IF EXISTS "Artist insert submissions" ON public.event_submissions;
CREATE POLICY "Artist insert submissions" ON public.event_submissions
FOR INSERT WITH CHECK (auth.uid() = artist_id);

-- Policy E: Artist boleh delete submisi mereka yang masih pending
DROP POLICY IF EXISTS "Artist delete pending submissions" ON public.event_submissions;
CREATE POLICY "Artist delete pending submissions" ON public.event_submissions
FOR DELETE USING (
  auth.uid() = artist_id 
  AND status = 'pending'
);

-- 7. RLS POLICIES untuk EVENTS (Update)
-- ===================================================================

-- Policy: Organizer boleh update event mereka sendiri
DROP POLICY IF EXISTS "Organizer update own events" ON public.events;
CREATE POLICY "Organizer update own events" ON public.events
FOR UPDATE USING (organizer_id = auth.uid());

-- Policy: Organizer boleh delete event mereka sendiri
DROP POLICY IF EXISTS "Organizer delete own events" ON public.events;
CREATE POLICY "Organizer delete own events" ON public.events
FOR DELETE USING (organizer_id = auth.uid());

-- 8. HELPER QUERY untuk Testing
-- ===================================================================

-- Query A: Buat user organizer test
-- (Ganti UUID dengan user ID yang sudah ada atau buat baru)
-- UPDATE public.profiles 
-- SET role = 'organizer'
-- WHERE id = 'USER_UUID_DISINI';

-- Query B: Lihat semua organizer
-- SELECT id, name, email, role 
-- FROM public.profiles 
-- WHERE role = 'organizer';

-- Query C: Lihat semua event dengan organizer
-- SELECT e.*, p.name as organizer_name
-- FROM public.events e
-- LEFT JOIN public.profiles p ON e.organizer_id = p.id;

-- Query D: Lihat semua submissions
-- SELECT 
--   es.*,
--   e.event_name,
--   a.title as artwork_title,
--   p.name as artist_name
-- FROM public.event_submissions es
-- JOIN public.events e ON es.event_id = e.id
-- JOIN public.artworks a ON es.artwork_id = a.id
-- JOIN public.profiles p ON es.artist_id = p.id
-- ORDER BY es.created_at DESC;

-- ===================================================================
-- SELESAI! Database sudah siap untuk Fase 1 Event Organizer
-- ===================================================================

-- CATATAN TESTING:
-- 1. Buat akun baru dengan email organizer (misal: organizer@test.com)
-- 2. Update role user tersebut menjadi 'organizer'
-- 3. Login dengan akun tersebut di aplikasi mobile
-- 4. Aplikasi akan otomatis redirect ke OrganizerMainScreen
-- 5. Untuk testing submission, buat event dulu di admin panel
--    dan set organizer_id ke UUID organizer
