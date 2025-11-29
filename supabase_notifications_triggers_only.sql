-- Notification Triggers and Functions Only
-- Run this if notifications table already exists
-- This will create automatic triggers for notifications

-- ============================================
-- 1. INDEXES (if not exist)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);

-- ============================================
-- 2. RLS POLICIES (drop existing first to avoid conflicts)
-- ============================================
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Service role can insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;

-- Create RLS policies
CREATE POLICY "Users can view their own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Service role can insert notifications"
  ON public.notifications
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can delete their own notifications"
  ON public.notifications
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- 3. TRIGGER FUNCTIONS
-- ============================================

-- Function to automatically create notification when artwork status changes
CREATE OR REPLACE FUNCTION notify_artwork_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create notification if status changed from 'pending' to 'approved' or 'rejected'
  IF OLD.status = 'pending' AND (NEW.status = 'approved' OR NEW.status = 'rejected') THEN
    INSERT INTO public.notifications (
      user_id,
      type,
      title,
      message,
      artwork_id,
      icon_type
    ) VALUES (
      NEW.artist_id,
      CASE 
        WHEN NEW.status = 'approved' THEN 'artwork_approved'
        WHEN NEW.status = 'rejected' THEN 'artwork_rejected'
      END,
      CASE 
        WHEN NEW.status = 'approved' THEN 'Karya Disetujui'
        WHEN NEW.status = 'rejected' THEN 'Karya Ditolak'
      END,
      CASE 
        WHEN NEW.status = 'approved' THEN 'Selamat! Karya "' || COALESCE(NEW.title, 'Untitled') || '" telah disetujui dan dipublikasikan.'
        WHEN NEW.status = 'rejected' THEN 'Karya "' || COALESCE(NEW.title, 'Untitled') || '" ditolak. Silakan periksa dan perbaiki karya Anda.'
      END,
      NEW.id,
      CASE 
        WHEN NEW.status = 'approved' THEN 'check'
        WHEN NEW.status = 'rejected' THEN 'close'
      END
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to notify organizer when new submission is created
CREATE OR REPLACE FUNCTION notify_new_submission()
RETURNS TRIGGER AS $$
DECLARE
  event_organizer_id uuid;
  event_title_text text;
  artwork_title_text text;
BEGIN
  -- Get event organizer and title
  SELECT organizer_id, title INTO event_organizer_id, event_title_text
  FROM public.events
  WHERE id = NEW.event_id;
  
  -- Get artwork title
  SELECT title INTO artwork_title_text
  FROM public.artworks
  WHERE id = NEW.artwork_id;
  
  -- Create notification for organizer (only if organizer_id exists)
  IF event_organizer_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id,
      type,
      title,
      message,
      event_id,
      submission_id,
      artwork_id,
      icon_type
    ) VALUES (
      event_organizer_id,
      'submission_new',
      'Submission Baru',
      'Karya "' || COALESCE(artwork_title_text, 'Untitled') || '" didaftarkan ke event "' || COALESCE(event_title_text, 'Event') || '"',
      NEW.event_id,
      NEW.id,
      NEW.artwork_id,
      'submission'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to notify when submission status changes (approved/rejected)
CREATE OR REPLACE FUNCTION notify_submission_status_change()
RETURNS TRIGGER AS $$
DECLARE
  event_title_text text;
  artwork_title_text text;
BEGIN
  -- Only notify if status changed from 'pending' to 'approved' or 'rejected'
  IF OLD.status = 'pending' AND (NEW.status = 'approved' OR NEW.status = 'rejected') THEN
    -- Get event and artwork titles
    SELECT title INTO event_title_text FROM public.events WHERE id = NEW.event_id;
    SELECT title INTO artwork_title_text FROM public.artworks WHERE id = NEW.artwork_id;
    
    INSERT INTO public.notifications (
      user_id,
      type,
      title,
      message,
      event_id,
      submission_id,
      artwork_id,
      icon_type
    ) VALUES (
      NEW.artist_id,
      CASE 
        WHEN NEW.status = 'approved' THEN 'submission_approved'
        WHEN NEW.status = 'rejected' THEN 'submission_rejected'
      END,
      CASE 
        WHEN NEW.status = 'approved' THEN 'Submission Disetujui'
        WHEN NEW.status = 'rejected' THEN 'Submission Ditolak'
      END,
      CASE 
        WHEN NEW.status = 'approved' THEN 'Karya "' || COALESCE(artwork_title_text, 'Untitled') || '" disetujui untuk event "' || COALESCE(event_title_text, 'Event') || '"'
        WHEN NEW.status = 'rejected' THEN 'Karya "' || COALESCE(artwork_title_text, 'Untitled') || '" ditolak untuk event "' || COALESCE(event_title_text, 'Event') || '"'
      END,
      NEW.event_id,
      NEW.id,
      NEW.artwork_id,
      CASE 
        WHEN NEW.status = 'approved' THEN 'check'
        WHEN NEW.status = 'rejected' THEN 'close'
      END
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to notify organizer when event status changes (approved/rejected)
CREATE OR REPLACE FUNCTION notify_event_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only notify if status changed from 'pending' to 'approved' or 'rejected'
  IF OLD.status = 'pending' AND (NEW.status = 'approved' OR NEW.status = 'rejected') THEN
    -- Only create notification if organizer_id exists
    IF NEW.organizer_id IS NOT NULL THEN
      INSERT INTO public.notifications (
        user_id,
        type,
        title,
        message,
        event_id,
        icon_type
      ) VALUES (
        NEW.organizer_id,
        CASE 
          WHEN NEW.status = 'approved' THEN 'event_approved'
          WHEN NEW.status = 'rejected' THEN 'event_rejected'
        END,
        CASE 
          WHEN NEW.status = 'approved' THEN 'Event Disetujui'
          WHEN NEW.status = 'rejected' THEN 'Event Ditolak'
        END,
        CASE 
          WHEN NEW.status = 'approved' THEN 'Selamat! Event "' || COALESCE(NEW.title, 'Event Anda') || '" telah disetujui dan dipublikasikan.'
          WHEN NEW.status = 'rejected' THEN 'Event "' || COALESCE(NEW.title, 'Event Anda') || '" ditolak. ' || COALESCE(NEW.rejection_reason, 'Silakan periksa kembali detail event Anda.')
        END,
        NEW.id,
        CASE 
          WHEN NEW.status = 'approved' THEN 'check'
          WHEN NEW.status = 'rejected' THEN 'close'
        END
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 4. CREATE TRIGGERS
-- ============================================

-- Drop existing triggers to avoid conflicts
DROP TRIGGER IF EXISTS artwork_status_notification_trigger ON public.artworks;
DROP TRIGGER IF EXISTS new_submission_notification_trigger ON public.event_submissions;
DROP TRIGGER IF EXISTS submission_status_notification_trigger ON public.event_submissions;
DROP TRIGGER IF EXISTS event_status_notification_trigger ON public.events;

-- Trigger for artwork status changes
CREATE TRIGGER artwork_status_notification_trigger
  AFTER UPDATE OF status ON public.artworks
  FOR EACH ROW
  EXECUTE FUNCTION notify_artwork_status_change();

-- Trigger for new event submissions
CREATE TRIGGER new_submission_notification_trigger
  AFTER INSERT ON public.event_submissions
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_submission();

-- Trigger for submission status changes
CREATE TRIGGER submission_status_notification_trigger
  AFTER UPDATE OF status ON public.event_submissions
  FOR EACH ROW
  EXECUTE FUNCTION notify_submission_status_change();

-- Trigger for event status changes (approved/rejected by admin)
CREATE TRIGGER event_status_notification_trigger
  AFTER UPDATE OF status ON public.events
  FOR EACH ROW
  EXECUTE FUNCTION notify_event_status_change();

-- ============================================
-- 5. TEST NOTIFICATION (for organizer)
-- ============================================

-- Uncomment and modify this to create a test notification
-- Replace 'YOUR_ORGANIZER_ID' with actual organizer user_id from profiles table

/*
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
  'Test Notification',
  'Ini adalah notifikasi test untuk organizer',
  'submission',
  false
);
*/

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Notification triggers and policies created successfully!';
  RAISE NOTICE '📝 To test: Uncomment and run the INSERT statement above';
  RAISE NOTICE '🔔 Triggers will auto-create notifications for:';
  RAISE NOTICE '   - Event approvals/rejections (to organizer)';
  RAISE NOTICE '   - New submissions to events (to organizer)';
  RAISE NOTICE '   - Submission approvals/rejections (to artist)';
  RAISE NOTICE '   - Artwork approvals/rejections (to artist)';
END $$;
