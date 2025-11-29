-- Test Notifications for Organizer
-- Run this AFTER running supabase_notifications_triggers_only.sql
-- Replace the user_id with your actual organizer ID

-- Get your organizer ID first (check from profiles or users table)
-- Example: SELECT id, username, role FROM profiles WHERE role = 'organizer';

-- INSERT TEST NOTIFICATIONS
-- Replace '468ccb0b-afec-412a-8ecd-3bb1c80965b8' with your actual organizer user_id

-- Test 1: New submission notification
INSERT INTO public.notifications (
  user_id,
  type,
  title,
  message,
  icon_type,
  is_read
) VALUES (
  '468ccb0b-afec-412a-8ecd-3bb1c80965b8', -- Replace with your organizer ID
  'submission_new',
  'Submission Baru',
  'Karya "Abstract Art" didaftarkan ke event "Pameran Seni 2025"',
  'submission',
  false
);

-- Test 2: Submission approved notification (untuk artist)
-- Get artist_id from profiles where role = 'artist'
/*
INSERT INTO public.notifications (
  user_id,
  type,
  title,
  message,
  icon_type,
  is_read
) VALUES (
  'ARTIST_USER_ID_HERE', -- Replace with artist ID
  'submission_approved',
  'Submission Disetujui',
  'Karya "My Artwork" disetujui untuk event "Event Test"',
  'check',
  false
);
*/

-- Test 3: Multiple notifications
INSERT INTO public.notifications (user_id, type, title, message, icon_type, is_read)
VALUES 
  ('468ccb0b-afec-412a-8ecd-3bb1c80965b8', 'submission_new', 'Submission Baru #1', 'Karya "Painting 1" didaftarkan', 'submission', false),
  ('468ccb0b-afec-412a-8ecd-3bb1c80965b8', 'submission_new', 'Submission Baru #2', 'Karya "Painting 2" didaftarkan', 'submission', false),
  ('468ccb0b-afec-412a-8ecd-3bb1c80965b8', 'submission_new', 'Submission Baru #3', 'Karya "Painting 3" didaftarkan', 'submission', true);

-- Verify notifications were created
SELECT 
  id,
  created_at,
  type,
  title,
  message,
  is_read,
  icon_type
FROM public.notifications 
WHERE user_id = '468ccb0b-afec-412a-8ecd-3bb1c80965b8'
ORDER BY created_at DESC
LIMIT 10;

-- Count unread notifications
SELECT COUNT(*) as unread_count
FROM public.notifications 
WHERE user_id = '468ccb0b-afec-412a-8ecd-3bb1c80965b8' 
AND is_read = false;
