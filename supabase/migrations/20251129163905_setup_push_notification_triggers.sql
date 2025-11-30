-- Push Notification Setup
-- This updates the existing notification triggers to also send push notifications via Edge Function

-- ============================================
-- 1. UPDATE TRIGGER FUNCTIONS TO CALL EDGE FUNCTION
-- ============================================

-- Function to send push notification via Edge Function
CREATE OR REPLACE FUNCTION send_push_notification_via_edge_function(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
DECLARE
  v_edge_function_url text;
BEGIN
  -- Get Edge Function URL from Supabase (replace with your actual URL)
  -- Format: https://[PROJECT_REF].supabase.co/functions/v1/send-push-notification
  v_edge_function_url := current_setting('app.settings.edge_function_url', true);
  
  -- If edge function URL not set, skip (for development)
  IF v_edge_function_url IS NULL OR v_edge_function_url = '' THEN
    RAISE NOTICE 'Edge function URL not configured, skipping push notification';
    RETURN;
  END IF;
  
  -- Call Edge Function asynchronously using pg_net (Supabase extension)
  PERFORM
    net.http_post(
      url := v_edge_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('request.jwt.claims', true)::json->>'sub'
      ),
      body := jsonb_build_object(
        'user_id', p_user_id,
        'title', p_title,
        'body', p_body,
        'data', p_data
      )
    );
    
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the main transaction
    RAISE NOTICE 'Error sending push notification: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 2. UPDATE EXISTING TRIGGER FUNCTIONS
-- ============================================

-- Update artwork status notification to include push
CREATE OR REPLACE FUNCTION notify_artwork_status_change()
RETURNS TRIGGER AS $$
DECLARE
  v_notification_id uuid;
BEGIN
  IF OLD.status = 'pending' AND (NEW.status = 'approved' OR NEW.status = 'rejected') THEN
    -- Insert notification to database
    INSERT INTO public.notifications (
      user_id, type, title, message, artwork_id, icon_type
    ) VALUES (
      NEW.artist_id,
      CASE WHEN NEW.status = 'approved' THEN 'artwork_approved' ELSE 'artwork_rejected' END,
      CASE WHEN NEW.status = 'approved' THEN 'Karya Disetujui' ELSE 'Karya Ditolak' END,
      CASE 
        WHEN NEW.status = 'approved' THEN 'Selamat! Karya "' || COALESCE(NEW.title, 'Untitled') || '" telah disetujui dan dipublikasikan.'
        ELSE 'Karya "' || COALESCE(NEW.title, 'Untitled') || '" ditolak. Silakan periksa dan perbaiki karya Anda.'
      END,
      NEW.id,
      CASE WHEN NEW.status = 'approved' THEN 'check' ELSE 'close' END
    ) RETURNING id INTO v_notification_id;
    
    -- Send push notification
    PERFORM send_push_notification_via_edge_function(
      NEW.artist_id,
      CASE WHEN NEW.status = 'approved' THEN 'Karya Disetujui ✅' ELSE 'Karya Ditolak ❌' END,
      CASE 
        WHEN NEW.status = 'approved' THEN 'Karya "' || COALESCE(NEW.title, 'Untitled') || '" telah disetujui!'
        ELSE 'Karya "' || COALESCE(NEW.title, 'Untitled') || '" ditolak.'
      END,
      jsonb_build_object(
        'type', 'artwork_status',
        'artwork_id', NEW.id,
        'notification_id', v_notification_id
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update new submission notification to include push
CREATE OR REPLACE FUNCTION notify_new_submission()
RETURNS TRIGGER AS $$
DECLARE
  event_organizer_id uuid;
  event_title_text text;
  artwork_title_text text;
  v_notification_id uuid;
BEGIN
  SELECT organizer_id, title INTO event_organizer_id, event_title_text
  FROM public.events WHERE id = NEW.event_id;
  
  SELECT title INTO artwork_title_text
  FROM public.artworks WHERE id = NEW.artwork_id;
  
  IF event_organizer_id IS NOT NULL THEN
    -- Insert notification to database
    INSERT INTO public.notifications (
      user_id, type, title, message, event_id, submission_id, artwork_id, icon_type
    ) VALUES (
      event_organizer_id,
      'submission_new',
      'Submission Baru',
      'Karya "' || COALESCE(artwork_title_text, 'Untitled') || '" didaftarkan ke event "' || COALESCE(event_title_text, 'Event') || '"',
      NEW.event_id, NEW.id, NEW.artwork_id, 'submission'
    ) RETURNING id INTO v_notification_id;
    
    -- Send push notification
    PERFORM send_push_notification_via_edge_function(
      event_organizer_id,
      'Submission Baru 📤',
      'Karya "' || COALESCE(artwork_title_text, 'Untitled') || '" didaftarkan ke event Anda',
      jsonb_build_object(
        'type', 'new_submission',
        'event_id', NEW.event_id,
        'submission_id', NEW.id,
        'notification_id', v_notification_id
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update submission status notification to include push
CREATE OR REPLACE FUNCTION notify_submission_status_change()
RETURNS TRIGGER AS $$
DECLARE
  event_title_text text;
  artwork_title_text text;
  v_notification_id uuid;
BEGIN
  IF OLD.status = 'pending' AND (NEW.status = 'approved' OR NEW.status = 'rejected') THEN
    SELECT title INTO event_title_text FROM public.events WHERE id = NEW.event_id;
    SELECT title INTO artwork_title_text FROM public.artworks WHERE id = NEW.artwork_id;
    
    -- Insert notification to database
    INSERT INTO public.notifications (
      user_id, type, title, message, event_id, submission_id, artwork_id, icon_type
    ) VALUES (
      NEW.artist_id,
      CASE WHEN NEW.status = 'approved' THEN 'submission_approved' ELSE 'submission_rejected' END,
      CASE WHEN NEW.status = 'approved' THEN 'Submission Disetujui' ELSE 'Submission Ditolak' END,
      CASE 
        WHEN NEW.status = 'approved' THEN 'Karya "' || COALESCE(artwork_title_text, 'Untitled') || '" disetujui untuk event "' || COALESCE(event_title_text, 'Event') || '"'
        ELSE 'Karya "' || COALESCE(artwork_title_text, 'Untitled') || '" ditolak untuk event "' || COALESCE(event_title_text, 'Event') || '"'
      END,
      NEW.event_id, NEW.id, NEW.artwork_id,
      CASE WHEN NEW.status = 'approved' THEN 'check' ELSE 'close' END
    ) RETURNING id INTO v_notification_id;
    
    -- Send push notification
    PERFORM send_push_notification_via_edge_function(
      NEW.artist_id,
      CASE WHEN NEW.status = 'approved' THEN 'Submission Disetujui ✅' ELSE 'Submission Ditolak ❌' END,
      CASE 
        WHEN NEW.status = 'approved' THEN 'Submission untuk "' || COALESCE(event_title_text, 'Event') || '" disetujui!'
        ELSE 'Submission untuk "' || COALESCE(event_title_text, 'Event') || '" ditolak.'
      END,
      jsonb_build_object(
        'type', 'submission_status',
        'event_id', NEW.event_id,
        'submission_id', NEW.id,
        'notification_id', v_notification_id
      )
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update event status notification to include push
CREATE OR REPLACE FUNCTION notify_event_status_change()
RETURNS TRIGGER AS $$
DECLARE
  v_notification_id uuid;
BEGIN
  IF OLD.status = 'pending' AND (NEW.status = 'approved' OR NEW.status = 'rejected') THEN
    IF NEW.organizer_id IS NOT NULL THEN
      -- Insert notification to database
      INSERT INTO public.notifications (
        user_id, type, title, message, event_id, icon_type
      ) VALUES (
        NEW.organizer_id,
        CASE WHEN NEW.status = 'approved' THEN 'event_approved' ELSE 'event_rejected' END,
        CASE WHEN NEW.status = 'approved' THEN 'Event Disetujui' ELSE 'Event Ditolak' END,
        CASE 
          WHEN NEW.status = 'approved' THEN 'Selamat! Event "' || COALESCE(NEW.title, 'Event Anda') || '" telah disetujui dan dipublikasikan.'
          ELSE 'Event "' || COALESCE(NEW.title, 'Event Anda') || '" ditolak. ' || COALESCE(NEW.rejection_reason, 'Silakan periksa kembali detail event Anda.')
        END,
        NEW.id,
        CASE WHEN NEW.status = 'approved' THEN 'check' ELSE 'close' END
      ) RETURNING id INTO v_notification_id;
      
      -- Send push notification
      PERFORM send_push_notification_via_edge_function(
        NEW.organizer_id,
        CASE WHEN NEW.status = 'approved' THEN 'Event Disetujui 🎉' ELSE 'Event Ditolak ❌' END,
        CASE 
          WHEN NEW.status = 'approved' THEN 'Event "' || COALESCE(NEW.title, 'Event Anda') || '" telah dipublikasikan!'
          ELSE 'Event "' || COALESCE(NEW.title, 'Event Anda') || '" ditolak.'
        END,
        jsonb_build_object(
          'type', 'event_status',
          'event_id', NEW.id,
          'notification_id', v_notification_id
        )
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 3. RECREATE TRIGGERS (to use updated functions)
-- ============================================

DROP TRIGGER IF EXISTS artwork_status_notification_trigger ON public.artworks;
DROP TRIGGER IF EXISTS new_submission_notification_trigger ON public.event_submissions;
DROP TRIGGER IF EXISTS submission_status_notification_trigger ON public.event_submissions;
DROP TRIGGER IF EXISTS event_status_notification_trigger ON public.events;

CREATE TRIGGER artwork_status_notification_trigger
  AFTER UPDATE OF status ON public.artworks
  FOR EACH ROW
  EXECUTE FUNCTION notify_artwork_status_change();

CREATE TRIGGER new_submission_notification_trigger
  AFTER INSERT ON public.event_submissions
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_submission();

CREATE TRIGGER submission_status_notification_trigger
  AFTER UPDATE OF status ON public.event_submissions
  FOR EACH ROW
  EXECUTE FUNCTION notify_submission_status_change();

CREATE TRIGGER event_status_notification_trigger
  AFTER UPDATE OF status ON public.events
  FOR EACH ROW
  EXECUTE FUNCTION notify_event_status_change();

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Push notification triggers updated successfully!';
  RAISE NOTICE '📱 Notifications will now be sent to devices via FCM';
  RAISE NOTICE '⚙️  Remember to:';
  RAISE NOTICE '   1. Deploy Edge Function: send-push-notification';
  RAISE NOTICE '   2. Set Firebase Server Key secret';
  RAISE NOTICE '   3. Configure edge_function_url in Supabase settings';
END $$;
