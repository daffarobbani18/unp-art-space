# 🔔 Push Notification Setup Guide

## Prerequisites
- Firebase Account (gratis): https://console.firebase.google.com
- Supabase CLI (optional untuk Edge Functions)

---

## 📱 Step 1: Firebase Setup

### 1.1 Create Firebase Project
1. Buka https://console.firebase.google.com
2. Klik **"Add project"** atau **"Create a project"**
3. Masukkan nama project: `unp-art-space`
4. Disable Google Analytics (optional)
5. Klik **"Create project"**

### 1.2 Add Android App
1. Di Firebase Console, klik **"Add app"** → pilih **Android**
2. **Android package name**: `com.example.unp_art_space_mobile` (sesuaikan dengan yang di `android/app/build.gradle.kts`)
3. **App nickname**: UNP Art Space
4. Klik **"Register app"**
5. **Download** `google-services.json`
6. Copy file ke: `android/app/google-services.json` (sudah ada, replace saja)

### 1.3 Enable FCM API V1 dan Get Service Account

**⚠️ PENTING: Service Account = Kunci Admin Firebase**
File ini memberikan akses penuh ke Firebase project. Jangan pernah:
- ❌ Commit ke Git/GitHub
- ❌ Share di public
- ❌ Hardcode di aplikasi

1. Di Firebase Console → **Project Settings** (⚙️ icon)
2. Tab **"Cloud Messaging"**
3. Cari **"Cloud Messaging API (V1)"** → klik **"Manage"**
4. **Enable** "Firebase Cloud Messaging API" jika belum
5. Kembali ke Firebase Console → **Project Settings** → Tab **"Service accounts"**
6. Klik **"Generate new private key"**
7. Download file JSON (misalnya: `unp-art-space-firebase-adminsdk.json`)
8. **SIMPAN FILE INI DENGAN AMAN** - tambahkan ke `.gitignore`:

```gitignore
# Firebase Service Account (NEVER COMMIT!)
*firebase-adminsdk*.json
```

---

## 🗄️ Step 2: Database Setup

### 2.1 Create FCM Tokens Table
Jalankan SQL ini di Supabase SQL Editor:

```sql
-- Run: supabase_fcm_tokens.sql
```

File `supabase_fcm_tokens.sql` sudah dibuat di root project.

### 2.2 Update Notification Triggers
Jalankan SQL ini di Supabase SQL Editor:

```sql
-- Run: supabase_push_notification_setup.sql
```

File `supabase_push_notification_setup.sql` sudah dibuat di root project.

---

## 🚀 Step 3: Supabase Edge Function Setup

### 3.1 Install Supabase CLI (if not installed)
```bash
# Windows (PowerShell)
scoop install supabase

# Or download from: https://github.com/supabase/cli/releases
```

### 3.2 Login to Supabase
```bash
supabase login
```

### 3.3 Link Project
```bash
supabase link --project-ref YOUR_PROJECT_REF
```

Dapatkan `YOUR_PROJECT_REF` dari Supabase Dashboard URL:
`https://app.supabase.com/project/YOUR_PROJECT_REF`

### 3.4 Create Edge Function
```bash
supabase functions new send-push-notification
```

Copy isi file `supabase/functions/send-push-notification/index.ts` dari project ini.

### 3.5 Set Firebase Service Account Secret
```bash
# Copy isi file JSON service account
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat unp-art-space-firebase-adminsdk.json)"
```

**Windows PowerShell:**
```powershell
# Read file dan set sebagai secret
$serviceAccount = Get-Content unp-art-space-firebase-adminsdk.json -Raw
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$serviceAccount"
```

Atau set manual via Supabase Dashboard:
1. Buka Project → Settings → Edge Functions → Secrets
2. Add secret: `FIREBASE_SERVICE_ACCOUNT`
3. Paste seluruh isi file JSON service account

### 3.6 Deploy Edge Function
```bash
supabase functions deploy send-push-notification
```

---

## 📱 Step 4: Flutter Implementation

### 4.1 Dependencies (sudah ada di pubspec.yaml)
```yaml
dependencies:
  firebase_core: ^3.10.0
  firebase_messaging: ^15.1.6
```

### 4.2 Update Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<!-- Already added, just verify -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

**iOS** (optional, if you build for iOS later):
- Already handled by firebase_messaging plugin

### 4.3 Run Flutter App
```bash
flutter pub get
flutter run
```

Saat pertama kali buka app, akan muncul permission dialog untuk notifikasi.
Klik **"Allow"** / **"Izinkan"**

---

## ✅ Step 5: Testing

### 5.1 Test Manual dari Firebase Console
1. Firebase Console → **Cloud Messaging**
2. Klik **"Send your first message"**
3. **Notification title**: Test Notifikasi
4. **Notification text**: Ini adalah test push notification
5. Klik **"Send test message"**
6. Paste **FCM Token** dari app log
7. Klik **"Test"**

### 5.2 Test Automatic Trigger
1. Login sebagai **Organizer**
2. Buat event baru
3. Login sebagai **Admin** (di device lain atau web)
4. Approve event tersebut
5. ✅ Organizer akan menerima **push notification** di device!

---

## 🔍 Troubleshooting

### Push notification tidak muncul?

**1. Cek FCM Token tersimpan:**
```sql
SELECT * FROM fcm_tokens WHERE user_id = 'YOUR_USER_ID';
```

**2. Cek log Edge Function:**
```bash
supabase functions logs send-push-notification
```

**3. Cek Android notification settings:**
- Settings → Apps → UNP Art Space → Notifications → Enable

**4. Cek log Flutter:**
```
flutter logs
```
Cari error `firebase_messaging` atau `FCM`

---

## 🆕 FCM API V1 vs Legacy

| Feature | Legacy API (Deprecated) | V1 API (New) |
|---------|------------------------|--------------|
| Status | ❌ Will be removed June 2024 | ✅ Active & Maintained |
| Auth | Server Key | OAuth 2.0 Access Token |
| Security | Less secure (static key) | More secure (rotating token) |
| Features | Basic | Enhanced targeting & analytics |
| Future support | None | Full support |

**Kita menggunakan FCM API V1** agar tidak perlu migrasi di masa depan!

## 💰 Cost Estimation

| Service | Free Tier | Cost After |
|---------|-----------|------------|
| Firebase FCM | Unlimited | Always FREE |
| Supabase Edge Functions | 500K requests/month | $0.02 per 10K |
| Supabase Database | 500 MB | Free for small apps |

**Total: $0** untuk usage normal (< 500K notifications/month)

---

## 📚 Additional Resources

- Firebase Documentation: https://firebase.google.com/docs/cloud-messaging
- Flutter Firebase Messaging: https://firebase.flutter.dev/docs/messaging/overview
- Supabase Edge Functions: https://supabase.com/docs/guides/functions

---

## 🎉 Summary

Setelah setup selesai:
- ✅ User dapat notifikasi push saat ada event penting
- ✅ Otomatis terkirim saat trigger database
- ✅ 100% gratis untuk usage normal
- ✅ Bekerja bahkan saat app tertutup (background)

Good luck! 🚀
