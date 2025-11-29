-- Notifications Table Schema
-- This table stores all in-app notifications for users

CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  user_id uuid NOT NULL, -- Recipient of the notification
  type text NOT NULL, -- 'artwork_approved', 'artwork_rejected', 'submission_new', 'comment', 'like', etc.
  title text NOT NULL,
  message text NOT NULL,
  is_read boolean DEFAULT false,
  
  -- Related entities (optional, for linking to specific items)
  artwork_id bigint,
  event_id uuid,
  submission_id uuid,
  
  -- Additional metadata
  action_url text, -- Deep link or URL to navigate when tapped
  icon_type text, -- Icon to show: 'check', 'close', 'event', 'artwork', etc.
  
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT notifications_artwork_id_fkey FOREIGN KEY (artwork_id) REFERENCES public.artworks(id) ON DELETE SET NULL,
  CONSTRAINT notifications_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE SET NULL,
  CONSTRAINT notifications_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.event_submissions(id) ON DELETE SET NULL
);

-- Create index for faster queries
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);

-- RLS (Row Level Security) Policies
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can only see their own notifications
CREATE POLICY "Users can view their own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update their own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id);

-- System/backend can insert notifications for any user
CREATE POLICY "Service role can insert notifications"
  ON public.notifications
  FOR INSERT
  WITH CHECK (true);

-- Optional: Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications"
  ON public.notifications
  FOR DELETE
  USING (auth.uid() = user_id);

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

-- Trigger for artwork status changes
DROP TRIGGER IF EXISTS artwork_status_notification_trigger ON public.artworks;
CREATE TRIGGER artwork_status_notification_trigger
  AFTER UPDATE OF status ON public.artworks
  FOR EACH ROW
  EXECUTE FUNCTION notify_artwork_status_change();

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
  
  -- Create notification for organizer
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
      'event'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new event submissions
DROP TRIGGER IF EXISTS new_submission_notification_trigger ON public.event_submissions;
CREATE TRIGGER new_submission_notification_trigger
  AFTER INSERT ON public.event_submissions
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_submission();

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

-- Trigger for submission status changes
DROP TRIGGER IF EXISTS submission_status_notification_trigger ON public.event_submissions;
CREATE TRIGGER submission_status_notification_trigger
  AFTER UPDATE OF status ON public.event_submissions
  FOR EACH ROW
  EXECUTE FUNCTION notify_submission_status_change();

-- Helpful queries for testing:

-- View all notifications for a user
-- SELECT * FROM notifications WHERE user_id = 'your-user-id' ORDER BY created_at DESC;

-- Count unread notifications
-- SELECT COUNT(*) FROM notifications WHERE user_id = 'your-user-id' AND is_read = false;

-- Mark notification as read
-- UPDATE notifications SET is_read = true WHERE id = 'notification-id';

-- Mark all notifications as read for a user
-- UPDATE notifications SET is_read = true WHERE user_id = 'your-user-id' AND is_read = false;

-- Delete old notifications (optional cleanup)
-- DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '30 days';
