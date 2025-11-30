# 🚀 Setup Backend Push Notification - Step by Step

## Status Saat Ini

✅ **Flutter App**: Sudah siap (local notifications configured)  
✅ **Edge Function**: Sudah ter-deploy  
✅ **FCM Tokens Table**: Sudah ada di database  
⏳ **Triggers & Secrets**: Perlu setup manual

---

## Langkah 1: Download Firebase Service Account JSON

### 1.1 Buka Firebase Console
1. Kunjungi: https://console.firebase.google.com/
2. Pilih project: **UNP ArtSpace**

### 1.2 Generate Service Account Key
1. Klik ⚙️ **Settings** (icon gear) di samping "Project Overview"
2. Pilih **Project settings**
3. Tab **Service accounts**
4. Klik **Generate new private key**
5. Konfirmasi dengan klik **Generate key**
6. File JSON akan terdownload otomatis

### 1.3 Simpan File
1. Rename file menjadi: `unp-art-space-firebase-adminsdk.json`
2. Pindahkan ke folder project: `d:\Mobile\unp-art-space-mobile\`
3. **PENTING**: Jangan commit file ini ke Git!

---

## Langkah 2: Set Supabase Secret

### 2.1 Via CLI (Recommended)

Buka PowerShell di folder project dan jalankan:

```powershell
# Load isi file JSON
$serviceAccount = Get-Content unp-art-space-firebase-adminsdk.json -Raw

# Set sebagai secret di Supabase
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$serviceAccount"
```

### 2.2 Via Dashboard (Alternative)

Jika CLI error, gunakan dashboard:

1. Buka: https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/settings/functions
2. Scroll ke bagian **Environment variables**
3. Klik **Add new secret**
4. Key: `FIREBASE_SERVICE_ACCOUNT`
5. Value: Copy-paste seluruh isi file JSON (termasuk { dan })
6. Klik **Save**

---

## Langkah 3: Jalankan SQL Scripts

### 3.1 Buka SQL Editor
Kunjungi: https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/sql/new

### 3.2 Setup Push Notification Triggers

Copy-paste script ini dan klik **Run**:

```sql
-- ============================================
-- SETUP PUSH NOTIFICATION TRIGGERS
-- ============================================

-- Function to call Edge Function for sending push notifications
CREATE OR REPLACE FUNCTION send_push_notification_via_edge_function(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_data jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Call Supabase Edge Function asynchronously
  -- This is done via http request to the Edge Function URL
  -- The Edge Function will handle FCM token lookup and sending
  
  PERFORM net.http_post(
    url := current_setting('app.settings.functions_url', true) || '/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    ),
    body := jsonb_build_object(
      'userId', p_user_id,
      'title', p_title,
      'body', p_body,
      'data', p_data
    )::text
  );
  
  RAISE NOTICE 'Push notification trigger called for user: %', p_user_id;
EXCEPTION
  WHEN OTHERS THEN
    -- Don't fail the main transaction if push notification fails
    RAISE NOTICE 'Failed to trigger push notification: %', SQLERRM;
END;
$$;

-- ============================================
-- UPDATE EXISTING NOTIFICATION TRIGGERS
-- ============================================

-- 1. Artwork Status Change Notifications
CREATE OR REPLACE FUNCTION notify_artwork_status_change()
RETURNS trigger AS $$
DECLARE
  artwork_title text;
  artist_id uuid;
  status_text text;
BEGIN
  -- Get artwork info
  SELECT title, user_id INTO artwork_title, artist_id
  FROM artworks WHERE id = NEW.id;

  -- Format status text
  status_text := CASE 
    WHEN NEW.status = 'approved' THEN 'disetujui'
    WHEN NEW.status = 'rejected' THEN 'ditolak'
    ELSE NEW.status
  END;

  -- Insert to notifications table
  INSERT INTO notifications (user_id, type, title, body, data, is_read)
  VALUES (
    artist_id,
    'artwork_status',
    'Status Karya Diperbarui',
    format('Karya "%s" telah %s', artwork_title, status_text),
    jsonb_build_object(
      'artwork_id', NEW.id,
      'status', NEW.status,
      'artwork_title', artwork_title
    ),
    false
  );

  -- Send push notification
  PERFORM send_push_notification_via_edge_function(
    artist_id,
    'Status Karya Diperbarui',
    format('Karya "%s" telah %s', artwork_title, status_text),
    jsonb_build_object(
      'artwork_id', NEW.id::text,
      'status', NEW.status,
      'type', 'artwork_status',
      'click_action', 'FLUTTER_NOTIFICATION_CLICK'
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old trigger if exists
DROP TRIGGER IF EXISTS artwork_status_notification_trigger ON artworks;

-- Create new trigger
CREATE TRIGGER artwork_status_notification_trigger
  AFTER UPDATE OF status ON artworks
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('approved', 'rejected'))
  EXECUTE FUNCTION notify_artwork_status_change();

-- 2. Event Status Change Notifications
CREATE OR REPLACE FUNCTION notify_event_status_change()
RETURNS trigger AS $$
DECLARE
  event_title text;
  organizer_id uuid;
  status_text text;
BEGIN
  SELECT title, organizer_id INTO event_title, organizer_id
  FROM events WHERE id = NEW.id;

  status_text := CASE 
    WHEN NEW.status = 'approved' THEN 'disetujui'
    WHEN NEW.status = 'rejected' THEN 'ditolak'
    ELSE NEW.status
  END;

  INSERT INTO notifications (user_id, type, title, body, data, is_read)
  VALUES (
    organizer_id,
    'event_status',
    'Status Event Diperbarui',
    format('Event "%s" telah %s', event_title, status_text),
    jsonb_build_object(
      'event_id', NEW.id,
      'status', NEW.status,
      'event_title', event_title
    ),
    false
  );

  -- Send push notification
  PERFORM send_push_notification_via_edge_function(
    organizer_id,
    'Status Event Diperbarui',
    format('Event "%s" telah %s', event_title, status_text),
    jsonb_build_object(
      'event_id', NEW.id::text,
      'status', NEW.status,
      'type', 'event_status',
      'click_action', 'FLUTTER_NOTIFICATION_CLICK'
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS event_status_notification_trigger ON events;

CREATE TRIGGER event_status_notification_trigger
  AFTER UPDATE OF status ON events
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('approved', 'rejected'))
  EXECUTE FUNCTION notify_event_status_change();

-- Success message
DO $$ 
BEGIN
  RAISE NOTICE '✅ Push notification triggers berhasil disetup!';
  RAISE NOTICE '📱 Notifikasi sekarang akan trigger push notification via Edge Function';
END $$;
```

---

## Langkah 4: Verifikasi Setup

### 4.1 Cek Edge Function Status

```powershell
supabase functions list
```

Output yang diharapkan:
```
send-push-notification  ✅ Deployed
```

### 4.2 Cek Secrets

```powershell
supabase secrets list
```

Output yang diharapkan:
```
FIREBASE_SERVICE_ACCOUNT  ✅ Set
```

### 4.3 Test Manual

Buka SQL Editor dan jalankan:

```sql
-- Ganti <your-user-id> dengan user_id organizer yang sedang login
INSERT INTO notifications (user_id, type, title, body, data)
VALUES (
  '<your-user-id>',
  'test',
  'Test Push Notification',
  'Ini adalah test push notification dari Supabase',
  '{"test": true}'::jsonb
);
```

**Expected Result**:
- ✅ Device organizer menerima push notification
- ✅ Ada bunyi notifikasi
- ✅ Heads-up display muncul di atas layar

---

## Langkah 5: Test End-to-End

### Skenario: Admin Approve Event

1. **Login sebagai Organizer** di device
2. **Upload Event** baru
3. **Login sebagai Admin** (web/device lain)
4. **Approve Event** tersebut
5. **Cek Device Organizer**: 
   - ✅ Push notification masuk
   - ✅ Ada sound dan vibration
   - ✅ Notifikasi muncul di notification tray

---

## Troubleshooting

### ❌ Push Notification Tidak Masuk

**Cek 1: Edge Function Logs**
```powershell
supabase functions logs send-push-notification --limit 20
```

**Cek 2: FCM Token Tersimpan**
```sql
SELECT * FROM fcm_tokens WHERE user_id = '<your-user-id>' AND is_active = true;
```

**Cek 3: Notification Table**
```sql
SELECT * FROM notifications 
WHERE user_id = '<your-user-id>' 
ORDER BY created_at DESC 
LIMIT 5;
```

### ❌ Error "Invalid Token"

**Solusi**: Token sudah expired/tidak valid
1. Uninstall app
2. Install ulang
3. Login lagi
4. Token baru akan otomatis tersimpan

### ❌ Error "Service Account Not Found"

**Solusi**: Secret belum diset dengan benar
```powershell
# Set ulang secret
$serviceAccount = Get-Content unp-art-space-firebase-adminsdk.json -Raw
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$serviceAccount"

# Restart Edge Function
supabase functions deploy send-push-notification
```

---

## 📋 Checklist

Sebelum testing, pastikan semua ini sudah ✅:

- [ ] Firebase Service Account JSON sudah didownload
- [ ] Secret `FIREBASE_SERVICE_ACCOUNT` sudah diset di Supabase
- [ ] SQL script triggers sudah dijalankan
- [ ] Edge Function `send-push-notification` sudah deployed
- [ ] Tabel `fcm_tokens` sudah ada di database
- [ ] App Flutter sudah di-build ulang (karena ada perubahan gradle)
- [ ] Permission notification sudah di-grant di device

---

## 🎉 Setelah Semua Berhasil

Sistem push notification sudah berjalan penuh! Setiap kali:

- ✅ Admin approve/reject event → Organizer dapat push notification
- ✅ Admin approve/reject artwork → Artist dapat push notification
- ✅ Notifikasi muncul dengan sound dan vibration
- ✅ Multi-device support (1 user bisa dapat notif di banyak device)
- ✅ Auto cleanup token yang tidak valid

---

## 📚 File Referensi

- **Testing Guide**: `NOTIFICATION_TESTING_GUIDE.md`
- **FCM Setup Guide**: `PUSH_NOTIFICATION_SETUP.md`
- **Edge Function**: `supabase/functions/send-push-notification/index.ts`
- **Flutter Service**: `lib/app/Features/notifications/services/firebase_messaging_service.dart`
