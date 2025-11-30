# 📱 Panduan Lengkap Setup Push Notification - FCM + Supabase Edge Function

## 📋 Daftar Isi
1. [Arsitektur Sistem](#arsitektur-sistem)
2. [Prasyarat](#prasyarat)
3. [Setup Firebase](#setup-firebase)
4. [Setup Supabase Database](#setup-supabase-database)
5. [Setup Supabase Edge Function](#setup-supabase-edge-function)
6. [Setup Flutter](#setup-flutter)
7. [Testing & Debugging](#testing--debugging)
8. [Troubleshooting](#troubleshooting)

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FLOW PUSH NOTIFICATION                       │
└─────────────────────────────────────────────────────────────────────┘

1. Admin Approve Event (Web/App)
   ↓
2. PostgreSQL Trigger: event_status_notification_trigger
   ↓
3. Function: notify_event_status_change()
   ├─→ INSERT ke tabel notifications (in-app notification)
   └─→ CALL send_push_notification_via_edge_function() (push notification)
       ↓
4. Supabase Edge Function: send-push-notification
   ├─→ Query fcm_tokens untuk dapat device token user
   ├─→ Authenticate ke Firebase dengan Service Account (OAuth 2.0)
   └─→ Kirim ke FCM API V1: https://fcm.googleapis.com/v1/projects/{projectId}/messages:send
       ↓
5. Firebase Cloud Messaging
   ↓
6. Device User (Android/iOS)
   ├─→ Background: System tray notification
   ├─→ Foreground: flutter_local_notifications tampilkan notification
   └─→ Terminated: Launch app saat notification di-tap
```

### Komponen-Komponen:

#### Backend (Supabase):
- **Database Tables**: `fcm_tokens`, `notifications`
- **Database Triggers**: 4 triggers untuk auto-notification
- **Database Functions**: Helper function untuk panggil Edge Function
- **Edge Function**: `send-push-notification` (Deno/TypeScript)

#### Frontend (Flutter):
- **firebase_messaging**: Handle FCM token & receive messages
- **flutter_local_notifications**: Display notification di foreground
- **FirebaseMessagingService**: Custom service untuk manage FCM

#### External Services:
- **Firebase Console**: Project & Service Account
- **FCM API V1**: Send notification endpoint

---

## 🔧 Prasyarat

### 1. Tools yang Dibutuhkan:
- ✅ Flutter SDK 3.35.2+
- ✅ Supabase CLI (sudah terinstall)
- ✅ Firebase Project (sudah ada)
- ✅ VS Code / Android Studio
- ✅ Android Device/Emulator untuk testing

### 2. Akses yang Dibutuhkan:
- ✅ Akses ke Firebase Console
- ✅ Akses ke Supabase Dashboard
- ✅ Permission untuk deploy Edge Function
- ✅ Permission untuk set Secrets di Supabase

### 3. File yang Harus Ada:
```
✅ android/app/google-services.json
✅ android/build.gradle.kts (plugin google-services)
✅ supabase/functions/send-push-notification/index.ts
✅ lib/app/Features/notifications/services/firebase_messaging_service.dart
```

---

## 🔥 Setup Firebase

### Langkah 1: Download Service Account JSON

1. **Buka Firebase Console:**
   ```
   https://console.firebase.google.com/
   ```

2. **Pilih Project:** UNP ArtSpace (atau project Anda)

3. **Navigate ke Service Account:**
   - Klik ⚙️ **Settings** (icon gear) di sidebar kiri
   - Klik **Project settings**
   - Tab **Service accounts**

4. **Generate Private Key:**
   - Scroll ke bawah
   - Klik button **"Generate new private key"**
   - Confirm di popup
   - File JSON akan ter-download otomatis

5. **Rename & Simpan File:**
   ```powershell
   # Rename file yang ter-download
   # Dari: unp-artspace-xxxxx-firebase-adminsdk-xxxxx.json
   # Ke: unp-art-space-firebase-adminsdk.json
   
   # Pindahkan ke root project (JANGAN commit ke Git!)
   Move-Item Downloads\unp-artspace-*.json D:\Mobile\unp-art-space-mobile\unp-art-space-firebase-adminsdk.json
   ```

6. **⚠️ PENTING - Keamanan:**
   ```bash
   # Tambahkan ke .gitignore
   echo "*firebase-adminsdk*.json" >> .gitignore
   ```
   **JANGAN PERNAH** commit file ini ke Git/GitHub!

### Langkah 2: Verifikasi Service Account JSON

File harus berisi struktur seperti ini:
```json
{
  "type": "service_account",
  "project_id": "unp-artspace-xxxxx",
  "private_key_id": "xxxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@unp-artspace-xxxxx.iam.gserviceaccount.com",
  "client_id": "xxxxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

**Yang paling penting:**
- ✅ `private_key`: Harus ada dan valid (format PEM)
- ✅ `client_email`: Email service account
- ✅ `project_id`: ID Firebase project

---

## 💾 Setup Supabase Database

### Langkah 1: Link Project Supabase

```powershell
# Di terminal, pastikan di folder project
cd D:\Mobile\unp-art-space-mobile

# Link ke project Supabase UNP ArtSpace
supabase link --project-ref vepmvxiddwmpetxfdwjn
```

**Output yang diharapkan:**
```
Initialising login role...
Connecting to remote database...
Finished supabase link.
```

### Langkah 2: Buat Tabel FCM Tokens

**File:** `supabase_fcm_tokens.sql` (sudah ada di project)

**Penjelasan Tabel:**
```sql
CREATE TABLE public.fcm_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  user_id uuid NOT NULL,              -- FK ke profiles (id user)
  token text NOT NULL UNIQUE,          -- FCM device token dari Flutter
  device_id text,                      -- Identifier device (optional)
  platform text,                       -- 'android', 'ios', atau 'web'
  is_active boolean DEFAULT true,      -- Flag untuk inactive token
  
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
);
```

**RLS Policies:**
- Users hanya bisa akses token mereka sendiri
- Auto-cleanup token inactive > 90 hari

**Jalankan:**

**Option A - Via Supabase Dashboard:**
1. Buka: https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/sql/new
2. Copy-paste seluruh isi file `supabase_fcm_tokens.sql`
3. Klik **"Run"**

**Option B - Via CLI (jika berhasil):**
```powershell
# Buat migration
supabase migration new create_fcm_tokens

# Copy SQL ke migration
Copy-Item supabase_fcm_tokens.sql -Destination supabase\migrations\<timestamp>_create_fcm_tokens.sql

# Push ke remote
supabase db push
```

**Verifikasi:**
```sql
-- Cek tabel sudah dibuat
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'fcm_tokens';

-- Expected: fcm_tokens
```

### Langkah 3: Setup Notification Triggers

**File:** `supabase_push_notification_setup.sql` (sudah ada)

**Apa yang dilakukan script ini:**

#### A. Membuat Helper Function `send_push_notification_via_edge_function()`

```sql
CREATE OR REPLACE FUNCTION send_push_notification_via_edge_function(
  p_user_id uuid,      -- User yang akan terima notifikasi
  p_title text,        -- Judul notification
  p_body text,         -- Isi notification
  p_data jsonb         -- Data tambahan (untuk navigation)
)
RETURNS void
```

**Fungsi ini:**
- Memanggil Edge Function `send-push-notification` via HTTP
- Menggunakan `net.http_post()` (extension pg_net)
- Async call - tidak block main transaction
- Error handling - tidak break trigger jika gagal

**⚠️ CATATAN PENTING:**
Fungsi ini perlu **Supabase URL** dan **Service Role Key**. Ada 2 cara set:

**Cara 1: Hardcode URL (untuk testing - TIDAK untuk production):**
```sql
-- Di fungsi, ganti:
v_supabase_url := 'https://vepmvxiddwmpetxfdwjn.supabase.co';
v_service_role_key := 'eyJhbGc...'; -- Service role key dari dashboard
```

**Cara 2: Database Settings (RECOMMENDED):**
```sql
-- Set via ALTER DATABASE (run sekali saja)
ALTER DATABASE postgres 
SET app.supabase_url = 'https://vepmvxiddwmpetxfdwjn.supabase.co';

ALTER DATABASE postgres 
SET app.service_role_key = 'eyJhbGc...'; -- Ambil dari Supabase Dashboard

-- Reload configuration
SELECT pg_reload_conf();
```

Ambil Service Role Key dari:
https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/settings/api

#### B. Update 4 Notification Triggers

Script ini meng-update 4 trigger functions:

1. **`notify_artwork_status_change()`**
   - Trigger: `AFTER UPDATE OF status ON artworks`
   - Event: Artwork diapprove/direject oleh admin
   - Notif ke: Uploader (user yang upload artwork)

2. **`notify_new_submission()`**
   - Trigger: `AFTER INSERT ON event_submissions`
   - Event: User submit karya ke event
   - Notif ke: Organizer event

3. **`notify_submission_status_change()`**
   - Trigger: `AFTER UPDATE OF status ON event_submissions`
   - Event: Submission diapprove/direject organizer
   - Notif ke: User yang submit

4. **`notify_event_status_change()`** ⭐ (UTAMA)
   - Trigger: `AFTER UPDATE OF status ON events`
   - Event: Event diapprove/direject oleh admin
   - Notif ke: Organizer event

**Setiap function melakukan 2 hal:**
1. INSERT ke tabel `notifications` (in-app notification)
2. CALL `send_push_notification_via_edge_function()` (push notification)

#### C. Fix Bug Ambiguitas Kolom

**File:** `fix_notify_event_status_change.sql`

**Masalah:**
```
ERROR: column reference "organizer_id" is ambiguous
DETAIL: It could refer to either a PL/pgSQL variable or a table column.
```

**Root Cause:**
Query `SELECT organizer_id FROM events WHERE...` ambigu karena ada:
- Kolom tabel: `events.organizer_id`
- Variabel: `NEW.organizer_id`

**Solusi:**
Gunakan variabel lokal dan alias tabel:
```sql
DECLARE
  v_organizer_id uuid;
  v_event_title text;
BEGIN
  -- Alias tabel 'e' untuk menghindari ambiguitas
  SELECT e.title, e.organizer_id 
  INTO v_event_title, v_organizer_id
  FROM events e 
  WHERE e.id = NEW.id;
END;
```

**Jalankan Script:**

1. **Buka Supabase SQL Editor:**
   https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/sql/new

2. **Jalankan dalam urutan:**

   **Step 1:** Setup fungsi helper Edge Function
   ```sql
   -- Copy paste dari supabase_push_notification_setup.sql
   -- Bagian: CREATE FUNCTION send_push_notification_via_edge_function
   
   -- JANGAN LUPA set URL dan Service Role Key!
   ```

   **Step 2:** Update trigger functions
   ```sql
   -- Copy paste 4 CREATE OR REPLACE FUNCTION:
   -- 1. notify_artwork_status_change
   -- 2. notify_new_submission
   -- 3. notify_submission_status_change
   -- 4. notify_event_status_change (atau pakai fix_notify_event_status_change.sql)
   ```

   **Step 3:** Recreate triggers
   ```sql
   -- Copy paste bagian DROP TRIGGER dan CREATE TRIGGER
   -- Total 4 triggers
   ```

**Verifikasi:**
```sql
-- Cek fungsi helper ada
SELECT proname FROM pg_proc 
WHERE proname = 'send_push_notification_via_edge_function';

-- Cek triggers aktif
SELECT tgname, tgenabled FROM pg_trigger 
WHERE tgname IN (
  'artwork_status_notification_trigger',
  'new_submission_notification_trigger',
  'submission_status_notification_trigger',
  'event_status_notification_trigger'
);
-- tgenabled = 'O' artinya enabled
```

### Langkah 4: Enable Extension pg_net (Jika Belum)

```sql
-- Extension untuk HTTP calls dari database
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Verifikasi
SELECT extname FROM pg_extension WHERE extname = 'pg_net';
```

**Jika error "permission denied":**
- Extension pg_net biasanya sudah ada di Supabase
- Jika tidak ada, contact Supabase support atau pakai alternatif (webhook)

---

## ⚡ Setup Supabase Edge Function

### Langkah 1: Verifikasi Edge Function File

**File:** `supabase/functions/send-push-notification/index.ts`

**Struktur file:**
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Helper functions
async function getAccessToken(serviceAccount: any): Promise<string>
async function pemToArrayBuffer(pem: string): Promise<ArrayBuffer>
async function sendFCMMessage(...)

// Main handler
serve(async (req) => {
  // 1. Parse request body
  // 2. Get FCM tokens from database
  // 3. Get OAuth2 access token from Firebase
  // 4. Send to FCM API V1
  // 5. Mark invalid tokens as inactive
  // 6. Return response
})
```

**Komponen penting:**

1. **OAuth 2.0 Authentication:**
   ```typescript
   async function getAccessToken(serviceAccount: any): Promise<string> {
     // 1. Create JWT dengan RS256
     // 2. Sign dengan private key dari Service Account
     // 3. Exchange JWT untuk access token
     // 4. Return access token
   }
   ```

2. **FCM API V1 Payload:**
   ```typescript
   {
     message: {
       token: '<device_fcm_token>',
       notification: {
         title: 'Event Disetujui 🎉',
         body: 'Event "Workshop Flutter" telah dipublikasikan!'
       },
       data: {
         type: 'event_status',
         event_id: 'uuid',
         notification_id: 'uuid',
         click_action: 'FLUTTER_NOTIFICATION_CLICK'
       },
       android: {
         priority: 'high',
         notification: {
           sound: 'default',
           channel_id: 'high_importance_channel'
         }
       },
       apns: {
         payload: {
           aps: {
             sound: 'default',
             badge: 1,
             'content-available': 1
           }
         }
       }
     }
   }
   ```

3. **Error Handling:**
   - `UNREGISTERED`: Token invalid/app uninstalled → mark inactive
   - `INVALID_ARGUMENT`: Token format salah → mark inactive
   - Network error: Retry atau log error

### Langkah 2: Deploy Edge Function

```powershell
# Pastikan di folder project
cd D:\Mobile\unp-art-space-mobile

# Deploy function
supabase functions deploy send-push-notification
```

**Output yang diharapkan:**
```
Deploying send-push-notification (project ref: vepmvxiddwmpetxfdwjn)
Bundled send-push-notification (size: xxx KB)
Deployed send-push-notification
```

**Verifikasi:**
```powershell
# List functions
supabase functions list
```

**Expected output:**
```
ID                                   | NAME                   | STATUS | VERSION
-------------------------------------|------------------------|--------|--------
deb696da-...                         | send-push-notification | ACTIVE | 1
```

### Langkah 3: Set Firebase Service Account Secret

**Cara 1: Via Supabase CLI (RECOMMENDED):**

```powershell
# Load file JSON
$serviceAccount = Get-Content unp-art-space-firebase-adminsdk.json -Raw

# Set sebagai secret
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$serviceAccount"
```

**Output:**
```
Setting secret FIREBASE_SERVICE_ACCOUNT...
Finished setting secrets.
```

**Cara 2: Via Supabase Dashboard:**

1. Buka: https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/settings/functions
2. Scroll ke **"Function secrets"**
3. Klik **"Add new secret"**
4. Name: `FIREBASE_SERVICE_ACCOUNT`
5. Value: Copy-paste **SELURUH ISI** file JSON (multi-line OK)
6. Klik **"Save"**

**Verifikasi:**
```powershell
supabase secrets list
```

**Expected:**
```
NAME                      | DIGEST
--------------------------|--------------------------------------------------
FIREBASE_SERVICE_ACCOUNT  | cfb195f730378c6d77a888f012153dc54bfd3bd5...
SUPABASE_ANON_KEY         | ...
SUPABASE_SERVICE_ROLE_KEY | ...
SUPABASE_URL              | ...
```

**⚠️ PENTING:**
- Secret harus berupa **VALID JSON STRING**
- Jangan ada trailing comma atau syntax error
- Test dengan: `echo $serviceAccount | ConvertFrom-Json` (harus sukses)

### Langkah 4: Test Edge Function Manual

**Via curl:**
```powershell
# Ambil Service Role Key dari dashboard
$serviceRoleKey = "eyJhbGc..."

# Test call Edge Function
curl -X POST `
  "https://vepmvxiddwmpetxfdwjn.supabase.co/functions/v1/send-push-notification" `
  -H "Authorization: Bearer $serviceRoleKey" `
  -H "Content-Type: application/json" `
  -d '{
    "userId": "<user_uuid>",
    "title": "Test Notification",
    "body": "This is a test from curl",
    "data": {"type": "test"}
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "sentCount": 1,
  "results": [
    {
      "token": "...",
      "success": true
    }
  ]
}
```

**Cek Logs:**

Via Dashboard: https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/functions/send-push-notification/logs

Look for:
- ✅ "OAuth2 token obtained successfully"
- ✅ "FCM message sent successfully"
- ❌ "Error sending FCM message" (jika ada masalah)

---

## 📱 Setup Flutter

### Langkah 1: Dependencies

**File:** `pubspec.yaml`

```yaml
dependencies:
  firebase_core: ^4.2.1
  firebase_messaging: ^16.0.4
  flutter_local_notifications: ^18.0.1
  supabase_flutter: ^2.10.2
```

**Install:**
```powershell
flutter pub get
```

### Langkah 2: Android Configuration

#### A. Build Gradle (Project Level)

**File:** `android/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false
    // ... other plugins
}
```

#### B. Build Gradle (App Level)

**File:** `android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")  // ← PENTING!
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    compileSdk = 34
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true  // ← UNTUK flutter_local_notifications
    }
    
    defaultConfig {
        minSdk = 21  // Minimum untuk FCM
        targetSdk = 34
    }
}

dependencies {
    // Core library desugaring untuk flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

#### C. AndroidManifest.xml

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    
    <application
        android:name="${applicationName}"
        android:label="UNP ArtSpace"
        android:icon="@mipmap/ic_launcher">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <!-- Intent filter untuk notification click -->
            <intent-filter>
                <action android:name="FLUTTER_NOTIFICATION_CLICK" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
            
            <!-- Main launcher -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <!-- FCM Default Notification Channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />
        
        <!-- Default Notification Icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
        
        <!-- Default Notification Color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@android:color/holo_purple" />
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

**Penjelasan:**
- `POST_NOTIFICATIONS`: Permission untuk Android 13+ (API 33+)
- `FLUTTER_NOTIFICATION_CLICK`: Handle notification tap
- `high_importance_channel`: Default channel ID (harus match dengan Flutter)
- Meta-data: Konfigurasi FCM

### Langkah 3: Firebase Messaging Service

**File:** `lib/app/Features/notifications/services/firebase_messaging_service.dart`

**Struktur:**
```dart
class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging;
  final SupabaseClient _supabase;
  final FlutterLocalNotificationsPlugin _localNotifications;
  
  // Initialization
  Future<void> initialize() async {
    await _initializeLocalNotifications();  // Setup notification channel
    await _requestPermission();             // Request user permission
    await _saveFCMToken();                  // Save token to Supabase
    _setupMessageHandlers();                 // Setup listeners
  }
  
  // Local Notifications
  Future<void> _initializeLocalNotifications() async {
    // Android: Create high importance channel
    // iOS: Request permissions
  }
  
  // Foreground Notification
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    // Display using flutter_local_notifications
  }
  
  // Message Handlers
  void _setupMessageHandlers() {
    // Foreground: Show notification manually
    // Background: System handles
    // Terminated: getInitialMessage
  }
}
```

**Key Methods:**

#### A. Initialize Local Notifications
```dart
Future<void> _initializeLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  await _localNotifications.initialize(
    InitializationSettings(android: androidSettings, iOS: iosSettings),
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );

  // Create Android notification channel
  const androidChannel = AndroidNotificationChannel(
    'high_importance_channel',              // ID (match AndroidManifest)
    'High Importance Notifications',        // Name
    importance: Importance.high,             // ← PENTING untuk sound!
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  await _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);
}
```

**Kenapa perlu channel?**
- Android 8.0+ (API 26) requires notification channels
- `Importance.high` = Sound + Heads-up display
- `Importance.default` = Sound only (no heads-up)
- `Importance.low` = No sound

#### B. Request Permission
```dart
Future<void> _requestPermission() async {
  final settings = await _firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
}
```

#### C. Save FCM Token
```dart
Future<void> _saveFCMToken() async {
  final token = await _firebaseMessaging.getToken();
  if (token == null) return;
  
  final user = _supabase.auth.currentUser;
  if (user == null) return;
  
  // Upsert token (insert or update)
  final existingToken = await _supabase
      .from('fcm_tokens')
      .select()
      .eq('token', token)
      .maybeSingle();
  
  if (existingToken != null) {
    await _supabase.from('fcm_tokens').update({
      'user_id': user.id,
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('token', token);
  } else {
    await _supabase.from('fcm_tokens').insert({
      'user_id': user.id,
      'token': token,
      'platform': 'android',
      'is_active': true,
    });
  }
}
```

#### D. Setup Message Handlers
```dart
void _setupMessageHandlers() {
  // FOREGROUND: App open dan visible
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('📬 Foreground message received');
    _showForegroundNotification(message);  // ← Manual display!
    _handleNotificationData(message.data);
  });

  // BACKGROUND: App minimized
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📬 Notification tapped (background)');
    _handleNotificationTap(message.data);
  });

  // TERMINATED: App closed completely
  _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      debugPrint('📬 Notification tapped (terminated)');
      _handleNotificationTap(message.data);
    }
  });
}
```

#### E. Show Foreground Notification
```dart
Future<void> _showForegroundNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  const androidDetails = AndroidNotificationDetails(
    'high_importance_channel',                    // Channel ID
    'High Importance Notifications',              // Channel name
    channelDescription: 'Important notifications',
    importance: Importance.high,                   // ← Sound + heads-up
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  await _localNotifications.show(
    message.hashCode,                              // Notification ID
    notification.title,
    notification.body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: jsonEncode(message.data),             // For navigation
  );
}
```

### Langkah 4: Initialize FCM Service

**File:** `lib/app/core/navigation/auth_gate.dart`

```dart
class _AuthGateState extends State<AuthGate> {
  final FirebaseMessagingService _fcmService = FirebaseMessagingService();
  bool _fcmInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFCM();
  }

  Future<void> _initializeFCM() async {
    if (_fcmInitialized || kIsWeb) return;
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await _fcmService.initialize();
      _fcmInitialized = true;
    }
  }
}
```

**⚠️ PENTING:**
- FCM service **HARUS** diinisialisasi **SETELAH** user login
- Kenapa? Token perlu disimpan dengan `user_id`
- Jangan init jika `kIsWeb` (FCM tidak support web dengan cara ini)

---

## 🧪 Testing & Debugging

### Langkah 1: Build dan Run App

```powershell
# Clean build
flutter clean
flutter pub get

# Run di device
flutter run
```

**Cek Console Log:**
```
🔔 Firebase Messaging initialized
📱 Notification permission: granted
🎫 FCM Token: <token>
✅ FCM token saved to database
```

**Jika tidak ada log ini:**
- FCM service belum initialize
- User belum login
- Ada error (cek error message)

### Langkah 2: Verifikasi Token Tersimpan

```sql
-- Di Supabase SQL Editor
SELECT 
  user_id,
  token,
  platform,
  device_id,
  is_active,
  created_at
FROM fcm_tokens
WHERE is_active = true
ORDER BY created_at DESC;
```

**Expected:**
- ✅ Ada minimal 1 row
- ✅ `token` berisi FCM token (string panjang)
- ✅ `user_id` match dengan user yang login
- ✅ `is_active` = true

### Langkah 3: Test Manual Notification

```sql
-- Ambil user_id dari query di atas
DO $$
DECLARE
  v_user_id uuid := '<PASTE_USER_ID_DISINI>';
BEGIN
  -- Call fungsi send push notification
  PERFORM send_push_notification_via_edge_function(
    v_user_id,
    'Test Notification 🔔',
    'Ini adalah test push notification dari database',
    jsonb_build_object(
      'type', 'test',
      'message', 'Hello from Supabase!'
    )
  );
  
  RAISE NOTICE '✅ Test notification sent to user: %', v_user_id;
END $$;
```

**Expected Result:**
1. ✅ Notification muncul di device
2. ✅ Ada bunyi notification
3. ✅ Muncul di notification tray
4. ✅ Jika app di foreground: Heads-up display

**Jika TIDAK muncul:**

**Check A: Edge Function Logs**
- Buka: https://supabase.com/dashboard/project/vepmvxiddwmpetxfdwjn/functions/send-push-notification/logs
- Look for errors:
  - ❌ "Service Account not configured" → Secret belum di-set
  - ❌ "Invalid grant" → Service Account JSON salah
  - ❌ "UNREGISTERED" → FCM token invalid

**Check B: Flutter Console**
- Cek ada error di console saat notif diterima
- Jika app di foreground, harus ada log:
  ```
  📬 Foreground message received
  ✅ Local notification displayed
  ```

### Langkah 4: Test Event Approval Flow (End-to-End)

**Setup:**
1. Login sebagai organizer di device
2. Upload event baru
3. Event masuk status `pending`

**Test:**
1. Login sebagai admin (bisa di web/device lain)
2. Buka panel admin → Pending events
3. Klik Approve pada event yang diupload organizer

**Expected:**
- ✅ Organizer device menerima notification:
  - Title: "Event Disetujui 🎉"
  - Body: "Event \"[Nama Event]\" telah dipublikasikan!"
- ✅ Notification masuk ke tabel `notifications`
- ✅ Push notification terkirim ke device

**Debug jika gagal:**

```sql
-- Cek apakah INSERT ke notifications berhasil
SELECT * FROM notifications 
WHERE type = 'event_approved' 
ORDER BY created_at DESC 
LIMIT 1;

-- Cek trigger berjalan
-- Update event manual untuk test trigger
UPDATE events 
SET status = 'approved' 
WHERE id = '<event_id>' AND status = 'pending';
-- Seharusnya trigger notifikasi
```

### Langkah 5: Test Notification Tap Navigation

```dart
// Di firebase_messaging_service.dart
void _onNotificationTapped(NotificationResponse response) {
  if (response.payload == null) return;
  
  final data = jsonDecode(response.payload!);
  debugPrint('🔔 Notification tapped with data: $data');
  
  // Navigate based on type
  final type = data['type'];
  switch (type) {
    case 'event_status':
      final eventId = data['event_id'];
      // Navigate ke EventDetailPage
      break;
    case 'submission_status':
      final submissionId = data['submission_id'];
      // Navigate ke SubmissionDetailPage
      break;
    // ... other types
  }
}
```

---

## 🐛 Troubleshooting

### Problem 1: Notification Permission Denied

**Symptoms:**
- Permission dialog tidak muncul
- Log: `Notification permission: denied`

**Solutions:**

**A. Reset App Permissions:**
```powershell
# Uninstall app
adb uninstall com.campus.artspace

# Reinstall
flutter run
```

**B. Manual Grant Permission:**
- Settings → Apps → UNP ArtSpace → Permissions → Notifications → Allow

**C. Check Android API Level:**
```kotlin
// android/app/build.gradle.kts
defaultConfig {
    targetSdk = 34  // Must be 33+ for POST_NOTIFICATIONS
}
```

### Problem 2: FCM Token Null

**Symptoms:**
- Log: `FCM Token: null`
- Token tidak tersimpan ke database

**Solutions:**

**A. Check google-services.json:**
```powershell
# Pastikan file ada
ls android/app/google-services.json

# Expected: File exists
```

**B. Check Plugin Applied:**
```kotlin
// android/app/build.gradle.kts
plugins {
    id("com.google.gms.google-services")  // ← Harus ada!
}
```

**C. Sync Gradle:**
```powershell
cd android
./gradlew clean
./gradlew build
```

### Problem 3: Notification No Sound

**Symptoms:**
- Notification muncul tapi tidak ada suara
- Tidak ada heads-up display

**Solutions:**

**A. Check Channel Importance:**
```dart
// Harus Importance.high (bukan default atau low)
const androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  importance: Importance.high,  // ← PENTING!
  playSound: true,
);
```

**B. Check Device Settings:**
- Settings → Apps → UNP ArtSpace → Notifications
- Tap "High Importance Notifications" channel
- Set to "Urgent" atau "High priority"
- Enable sound

**C. Recreate Channel:**
```dart
// Delete old channel first
await _localNotifications
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.deleteNotificationChannel('high_importance_channel');

// Recreate with correct settings
await _localNotifications
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(androidChannel);
```

### Problem 4: Foreground Notification Not Showing

**Symptoms:**
- Background notification works
- Foreground notification tidak muncul

**Solutions:**

**A. Check Message Handler:**
```dart
// Harus ada listener ini
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  _showForegroundNotification(message);  // ← Jangan lupa panggil ini!
});
```

**B. Check Notification Display:**
```dart
// Pastikan ada code ini di _showForegroundNotification
await _localNotifications.show(
  message.hashCode,
  notification?.title,
  notification?.body,
  NotificationDetails(android: androidDetails),
);
```

### Problem 5: Edge Function Error "Invalid Grant"

**Symptoms:**
- Edge Function logs: `Error: invalid_grant`
- Push notification tidak terkirim

**Solutions:**

**A. Verify Service Account JSON:**
```powershell
# Read secret
supabase secrets list

# Delete and recreate
supabase secrets unset FIREBASE_SERVICE_ACCOUNT
$serviceAccount = Get-Content unp-art-space-firebase-adminsdk.json -Raw
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$serviceAccount"
```

**B. Check JSON Format:**
```powershell
# Validate JSON
$json = Get-Content unp-art-space-firebase-adminsdk.json -Raw
$json | ConvertFrom-Json
# Harus sukses tanpa error
```

**C. Regenerate Service Account:**
- Buka Firebase Console → Service Accounts
- Generate new private key
- Download dan set ulang secret

### Problem 6: Database Function Not Found

**Symptoms:**
- Error: `function send_push_notification_via_edge_function does not exist`

**Solutions:**

**A. Run Setup SQL:**
```sql
-- Copy-paste dari supabase_push_notification_setup.sql
-- Bagian CREATE FUNCTION send_push_notification_via_edge_function
```

**B. Set Database Config:**
```sql
ALTER DATABASE postgres 
SET app.supabase_url = 'https://vepmvxiddwmpetxfdwjn.supabase.co';

ALTER DATABASE postgres 
SET app.service_role_key = '<service_role_key>';

SELECT pg_reload_conf();
```

### Problem 7: Trigger Not Firing

**Symptoms:**
- Update event status tidak create notification
- Tabel notifications kosong

**Solutions:**

**A. Check Trigger Enabled:**
```sql
SELECT tgname, tgenabled 
FROM pg_trigger 
WHERE tgname = 'event_status_notification_trigger';

-- tgenabled harus 'O' (origin = enabled)
```

**B. Recreate Trigger:**
```sql
DROP TRIGGER IF EXISTS event_status_notification_trigger ON events;

CREATE TRIGGER event_status_notification_trigger
  AFTER UPDATE OF status ON events
  FOR EACH ROW
  EXECUTE FUNCTION notify_event_status_change();
```

**C. Test Trigger Manually:**
```sql
-- Insert test event
INSERT INTO events (title, organizer_id, status) 
VALUES ('Test Event', '<your_user_id>', 'pending');

-- Update status (should trigger notification)
UPDATE events 
SET status = 'approved' 
WHERE title = 'Test Event';

-- Check notifications created
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 1;
```

### Problem 8: Multiple Notifications

**Symptoms:**
- Satu event approval → multiple notifications
- Duplikasi notification

**Solutions:**

**A. Check Duplicate Triggers:**
```sql
-- List all triggers on events table
SELECT tgname FROM pg_trigger WHERE tgrelid = 'events'::regclass;

-- Should only have ONE event_status_notification_trigger
-- If multiple, drop duplicates
```

**B. Check FCM Token Duplicates:**
```sql
-- Check for duplicate tokens
SELECT token, COUNT(*) 
FROM fcm_tokens 
WHERE is_active = true 
GROUP BY token 
HAVING COUNT(*) > 1;

-- Delete duplicates, keep latest
DELETE FROM fcm_tokens 
WHERE id NOT IN (
  SELECT MAX(id) 
  FROM fcm_tokens 
  WHERE is_active = true 
  GROUP BY token
);
```

---

## 📊 Monitoring & Maintenance

### Daily Checks

```sql
-- 1. Active Tokens Count
SELECT COUNT(*) as active_tokens 
FROM fcm_tokens 
WHERE is_active = true;

-- 2. Notifications Today
SELECT COUNT(*) as notifications_today 
FROM notifications 
WHERE created_at >= CURRENT_DATE;

-- 3. Unread Notifications
SELECT 
  u.email,
  COUNT(*) as unread_count
FROM notifications n
JOIN profiles p ON n.user_id = p.id
JOIN auth.users u ON p.id = u.id
WHERE n.is_read = false
GROUP BY u.email
ORDER BY unread_count DESC;

-- 4. Recent Errors (check logs)
-- Via Edge Function logs dashboard
```

### Weekly Maintenance

```sql
-- Cleanup inactive tokens older than 90 days
SELECT cleanup_old_fcm_tokens();

-- Check for orphaned notifications
SELECT COUNT(*) 
FROM notifications n
LEFT JOIN profiles p ON n.user_id = p.id
WHERE p.id IS NULL;

-- Delete orphaned notifications
DELETE FROM notifications 
WHERE user_id NOT IN (SELECT id FROM profiles);
```

### Performance Optimization

```sql
-- Add indexes if queries slow
CREATE INDEX IF NOT EXISTS idx_notifications_user_created 
ON notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_unread 
ON notifications(user_id) WHERE is_read = false;

-- Analyze query performance
EXPLAIN ANALYZE 
SELECT * FROM notifications 
WHERE user_id = '<uuid>' AND is_read = false 
ORDER BY created_at DESC;
```

---

## 📚 Additional Resources

### Documentation Links

- **Firebase Cloud Messaging:**
  - API V1: https://firebase.google.com/docs/cloud-messaging/migrate-v1
  - Android Setup: https://firebase.google.com/docs/cloud-messaging/android/client

- **Flutter Packages:**
  - firebase_messaging: https://pub.dev/packages/firebase_messaging
  - flutter_local_notifications: https://pub.dev/packages/flutter_local_notifications

- **Supabase:**
  - Edge Functions: https://supabase.com/docs/guides/functions
  - Database Triggers: https://supabase.com/docs/guides/database/postgres-triggers
  - RLS Policies: https://supabase.com/docs/guides/auth/row-level-security

### Testing Tools

- **FCM Token Tester:**
  - https://fcm.googleapis.com/fcm/send (Legacy)
  - https://fcm.googleapis.com/v1/projects/{projectId}/messages:send (V1)

- **Postman Collection:**
  - Import collection untuk test Edge Function
  - Set environment variables: project_ref, service_role_key

---

## ✅ Checklist Setup Lengkap

### Firebase Setup
- [ ] Firebase project sudah ada
- [ ] Service Account JSON sudah di-download
- [ ] Service Account JSON tersimpan aman (JANGAN commit ke Git)
- [ ] google-services.json ada di `android/app/`

### Supabase Database Setup
- [ ] Project sudah di-link via CLI
- [ ] Tabel `fcm_tokens` sudah dibuat
- [ ] RLS policies aktif di `fcm_tokens`
- [ ] Fungsi `send_push_notification_via_edge_function` sudah dibuat
- [ ] Database settings (URL + Service Role Key) sudah di-set
- [ ] 4 trigger functions sudah di-update
- [ ] 4 triggers sudah aktif (tgenabled = 'O')
- [ ] Extension `pg_net` sudah enabled

### Supabase Edge Function Setup
- [ ] Edge Function sudah deploy
- [ ] Status function = ACTIVE
- [ ] Secret `FIREBASE_SERVICE_ACCOUNT` sudah di-set
- [ ] Secret valid (test dengan manual call)
- [ ] Logs tidak ada error

### Flutter Setup
- [ ] Dependencies sudah terinstall
- [ ] `android/app/build.gradle.kts` sudah tambah `coreLibraryDesugaring`
- [ ] `android/app/build.gradle.kts` sudah apply plugin `google-services`
- [ ] `AndroidManifest.xml` sudah lengkap (permissions + meta-data)
- [ ] `FirebaseMessagingService` sudah dibuat
- [ ] Service initialize di `auth_gate.dart` setelah login
- [ ] App sudah build tanpa error

### Testing
- [ ] App berjalan di device
- [ ] Permission dialog muncul dan di-approve
- [ ] Console log menunjukkan FCM initialized
- [ ] FCM token tersimpan ke database
- [ ] Test manual notification berhasil
- [ ] Event approval trigger notification
- [ ] Notification ada sound
- [ ] Notification tap navigation works

### Production Ready
- [ ] Service Account JSON di `.gitignore`
- [ ] No hardcoded secrets di code
- [ ] Error handling lengkap
- [ ] Monitoring setup (logs + alerts)
- [ ] Documentation lengkap untuk team

---

## 🎯 Summary

**Sistem push notification sudah lengkap dengan:**

1. **Backend:** Database triggers otomatis create notification + push
2. **Edge Function:** FCM API V1 dengan OAuth 2.0 (future-proof)
3. **Flutter:** Local notifications untuk foreground display
4. **Security:** RLS policies + secrets management
5. **Testing:** Manual test + end-to-end flow
6. **Monitoring:** Logs + maintenance queries

**Next Steps:**
1. Jalankan checklist setup di atas
2. Test notification flow end-to-end
3. Monitor logs untuk detect errors early
4. Optimize berdasarkan usage patterns

**Butuh bantuan?** Share hasil testing atau error logs yang muncul!
