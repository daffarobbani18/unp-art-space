# 🔍 Troubleshooting Push Notification - Checklist

## Langkah-langkah Debug:

### 1. ✅ Cek Backend Setup
- [x] Edge Function deployed: `send-push-notification` (ACTIVE)
- [x] Firebase Service Account secret sudah di-set
- [ ] **JALANKAN SCRIPT DEBUG**: Buka Supabase SQL Editor dan jalankan `debug_push_notification.sql`

### 2. 📱 Cek Flutter App

#### A. Cek Log di Console Flutter
Cari log ini saat app pertama kali jalan:
```
🔔 Firebase Messaging initialized
📱 Notification permission: granted/denied
🎫 FCM Token: <token>
✅ FCM token saved to database
```

#### B. Jika TIDAK ADA log di atas:
**Kemungkinan masalah**: FCM service tidak terinisialisasi atau Firebase tidak terkonfigurasi

**Solusi**:
1. Pastikan file `google-services.json` ada di `android/app/`
2. Cek `android/build.gradle.kts` ada plugin google-services
3. Restart app dengan `flutter run`

#### C. Jika ada log "FCM Token: xxx" TAPI tidak masuk database:
**Kemungkinan masalah**: Error saat save ke Supabase

**Cek log error** di console Flutter:
```
❌ Error saving FCM token: <error message>
```

**Solusi**:
- Pastikan user sudah login sebelum FCM initialize
- Cek RLS policy di tabel `fcm_tokens`

### 3. 🧪 Test Manual Push Notification

Jalankan query ini di Supabase SQL Editor (ganti `<user_id>` dengan ID user yang login):

```sql
-- Ambil user_id dari FCM tokens
SELECT user_id, token FROM fcm_tokens WHERE is_active = true LIMIT 1;

-- Test kirim notification manual
DO $$
DECLARE
  v_user_id uuid := '<GANTI_USER_ID_DISINI>';
BEGIN
  PERFORM send_push_notification_via_edge_function(
    v_user_id,
    'Test Notification 🔔',
    'Ini adalah test push notification',
    jsonb_build_object('type', 'test')
  );
  
  RAISE NOTICE '✅ Test notification sent!';
END $$;
```

**Expected Result**:
- Notifikasi muncul di device
- Ada bunyi notification
- Muncul di notification tray

**Jika TIDAK muncul**, cek Supabase Edge Function Logs:
https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/functions/send-push-notification/logs

### 4. 🎯 Test Event Approval Notification

#### Prasyarat:
1. Login sebagai organizer di device
2. Upload event baru (status: pending)
3. Cek di database event tersimpan:
```sql
SELECT id, title, status, organizer_id FROM events WHERE status = 'pending' ORDER BY created_at DESC LIMIT 1;
```

#### Test:
1. Login sebagai admin di web/device lain
2. Approve event yang baru diupload
3. **Expected**: Organizer device menerima push notification "Event Disetujui 🎉"

#### Jika TIDAK muncul:
**Cek trigger aktif**:
```sql
SELECT tgname, tgenabled FROM pg_trigger WHERE tgname = 'event_status_notification_trigger';
```

**Manually run fungsi** (untuk debug):
```sql
-- Ambil ID event pending
SELECT id FROM events WHERE status = 'pending' LIMIT 1;

-- Update status secara manual untuk trigger notification
UPDATE events SET status = 'approved' WHERE id = '<EVENT_ID>';
```

### 5. 🔥 Kemungkinan Masalah & Solusi

#### Masalah 1: "Function send_push_notification_via_edge_function does not exist"
**Solusi**: Jalankan SQL di Supabase:
```sql
-- File: fix_notify_event_status_change.sql (sudah dibuat)
-- Atau minimal jalankan ini:

CREATE OR REPLACE FUNCTION send_push_notification_via_edge_function(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void AS $$
BEGIN
  -- Async call to Edge Function via pg_net
  PERFORM net.http_post(
    url := current_setting('app.supabase_url') || '/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.supabase_service_role_key')
    ),
    body := jsonb_build_object(
      'userId', p_user_id,
      'title', p_title,
      'body', p_body,
      'data', p_data
    )
  );
  
  RAISE NOTICE 'Push notification queued for user: %', p_user_id;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error queuing push notification: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### Masalah 2: Android Build Error "core library desugaring"
**Status**: ✅ SUDAH DIPERBAIKI
- `coreLibraryDesugaring` sudah ditambahkan ke `build.gradle.kts`

#### Masalah 3: Notification permission granted tapi tidak muncul
**Status**: ✅ SUDAH DIPERBAIKI
- Local notification channel sudah dibuat dengan `Importance.high`
- Foreground message handler sudah menampilkan local notification

#### Masalah 4: Token tidak tersimpan di database
**Kemungkinan**:
- User belum login saat FCM initialize
- RLS policy block insert
- Network error

**Cek**:
```sql
-- Cek RLS policy
SELECT * FROM pg_policies WHERE tablename = 'fcm_tokens';

-- Test insert manual
INSERT INTO fcm_tokens (user_id, token, platform, is_active)
VALUES (
  auth.uid(), 
  'test_token_' || gen_random_uuid()::text, 
  'android', 
  true
);
```

### 6. 📊 Monitoring Dashboard

Buat query ini sebagai bookmark untuk monitoring:

```sql
-- Dashboard: Push Notification Status
SELECT 
  'Active FCM Tokens' as metric,
  count(*) as value
FROM fcm_tokens 
WHERE is_active = true

UNION ALL

SELECT 
  'Notifications Today' as metric,
  count(*) as value
FROM notifications
WHERE created_at >= CURRENT_DATE

UNION ALL

SELECT 
  'Unread Notifications' as metric,
  count(*) as value
FROM notifications
WHERE is_read = false;
```

## 🚀 Next Steps

1. **Jalankan `debug_push_notification.sql`** di Supabase untuk cek status
2. **Restart Flutter app** dan lihat console log
3. **Test manual notification** dengan query di atas
4. **Report hasil** - mana langkah yang berhasil/gagal

## 📞 Butuh Bantuan?

Jika masih bermasalah, kasih tau saya:
1. Log apa yang muncul di Flutter console?
2. Hasil query dari `debug_push_notification.sql`?
3. Ada error di Supabase Edge Function logs?
