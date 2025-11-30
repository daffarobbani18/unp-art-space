-- Fix: Ambiguitas kolom organizer_id di fungsi notify_event_status_change
-- Gunakan alias tabel yang jelas untuk menghindari konflik dengan variabel PL/pgSQL

CREATE OR REPLACE FUNCTION notify_event_status_change()
RETURNS TRIGGER AS $$
DECLARE
  v_notification_id uuid;
  v_event_title text;
  v_organizer_id uuid;
BEGIN
  -- Hanya jalankan jika status berubah dari pending ke approved/rejected
  IF OLD.status = 'pending' AND (NEW.status = 'approved' OR NEW.status = 'rejected') THEN
    -- Ambil data event dengan alias tabel yang jelas
    SELECT e.title, e.organizer_id 
    INTO v_event_title, v_organizer_id
    FROM events e 
    WHERE e.id = NEW.id;
    
    IF v_organizer_id IS NOT NULL THEN
      -- Insert notification ke database
      INSERT INTO public.notifications (
        user_id, type, title, message, event_id, icon_type
      ) VALUES (
        v_organizer_id,
        CASE WHEN NEW.status = 'approved' THEN 'event_approved' ELSE 'event_rejected' END,
        CASE WHEN NEW.status = 'approved' THEN 'Event Disetujui' ELSE 'Event Ditolak' END,
        CASE 
          WHEN NEW.status = 'approved' THEN 'Selamat! Event "' || COALESCE(v_event_title, 'Event Anda') || '" telah disetujui dan dipublikasikan.'
          ELSE 'Event "' || COALESCE(v_event_title, 'Event Anda') || '" ditolak. ' || COALESCE(NEW.rejection_reason, 'Silakan periksa kembali detail event Anda.')
        END,
        NEW.id,
        CASE WHEN NEW.status = 'approved' THEN 'check' ELSE 'close' END
      ) RETURNING id INTO v_notification_id;
      
      -- Kirim push notification via Edge Function
      PERFORM send_push_notification_via_edge_function(
        v_organizer_id,
        CASE WHEN NEW.status = 'approved' THEN 'Event Disetujui 🎉' ELSE 'Event Ditolak ❌' END,
        CASE 
          WHEN NEW.status = 'approved' THEN 'Event "' || COALESCE(v_event_title, 'Event Anda') || '" telah dipublikasikan!'
          ELSE 'Event "' || COALESCE(v_event_title, 'Event Anda') || '" ditolak.'
        END,
        jsonb_build_object(
          'type', 'event_status',
          'event_id', NEW.id,
          'status', NEW.status,
          'notification_id', v_notification_id
        )
      );
      
      RAISE NOTICE 'Push notification sent to organizer % for event %', v_organizer_id, NEW.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS event_status_notification_trigger ON public.events;

CREATE TRIGGER event_status_notification_trigger
  AFTER UPDATE OF status ON public.events
  FOR EACH ROW
  EXECUTE FUNCTION notify_event_status_change();

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Fungsi notify_event_status_change() berhasil diperbaiki!';
  RAISE NOTICE '📝 Ambiguitas kolom organizer_id sudah diselesaikan dengan menggunakan variabel lokal';
END $$;
