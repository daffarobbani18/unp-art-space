# 🔔 Push Notification Testing Guide

## ✅ Completed Changes

### 1. Android Configuration
- **File**: `android/app/src/main/AndroidManifest.xml`
- **Added**:
  - Intent filter for `FLUTTER_NOTIFICATION_CLICK`
  - Default notification channel metadata: `high_importance_channel`
  - Default notification icon and color

### 2. Flutter Service Implementation
- **File**: `lib/app/Features/notifications/services/firebase_messaging_service.dart`
- **Added**:
  - `flutter_local_notifications` plugin integration
  - High importance notification channel creation
  - Foreground notification display handler
  - Notification tap handler with payload support

### 3. Dependencies
- **File**: `pubspec.yaml`
- **Added**: `flutter_local_notifications: ^18.0.1`

## 🧪 Testing Steps

### Phase 1: Local Testing (Current Device)

#### Test 1: Foreground Notification
1. Run the app: `flutter run`
2. Grant notification permission when prompted
3. Keep app open and in foreground
4. Trigger a test notification (use SQL or admin action)
5. **Expected Result**:
   - ✅ Notification sound plays
   - ✅ Heads-up display appears at top of screen
   - ✅ Notification appears in system tray
   - ✅ Debug log shows: "✅ Local notification displayed"

#### Test 2: Background Notification
1. With app running, minimize it (press home button)
2. Trigger a test notification
3. **Expected Result**:
   - ✅ Notification sound plays
   - ✅ Notification appears in system tray
   - ✅ Tapping notification opens app

#### Test 3: Terminated App Notification
1. Close app completely (swipe away from recent apps)
2. Trigger a test notification
3. **Expected Result**:
   - ✅ Notification sound plays
   - ✅ Notification appears in system tray
   - ✅ Tapping notification launches app

### Phase 2: Backend Setup

Before testing end-to-end, you need to deploy the push notification system to Supabase.

#### Step 1: Run Database Migrations

Run these SQL scripts in Supabase SQL Editor (in order):

1. **Create FCM Tokens Table**:
```sql
-- Run: supabase_fcm_tokens.sql
-- Creates table for storing device tokens
```

2. **Setup Push Notification Triggers**:
```sql
-- Run: supabase_push_notification_setup.sql
-- Updates all notification triggers to send push notifications
```

#### Step 2: Deploy Edge Function

```powershell
# Make sure you're in the project directory
cd d:\Mobile\unp-art-space-mobile

# Deploy the Edge Function
supabase functions deploy send-push-notification
```

#### Step 3: Set Firebase Service Account Secret

```powershell
# Load service account JSON and set as secret
$serviceAccount = Get-Content unp-art-space-firebase-adminsdk.json -Raw
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$serviceAccount"
```

#### Step 4: Verify Edge Function

```powershell
# Check if function is deployed
supabase functions list

# View function logs
supabase functions logs send-push-notification
```

### Phase 3: End-to-End Testing

#### Test 1: Event Approval Notification
1. **Setup**:
   - Login as organizer on device (make sure FCM token is saved)
   - Upload a new event as organizer
   - Wait for event to appear in "Pending Approval" status

2. **Action**:
   - Login as admin on web/another device
   - Approve the event

3. **Expected Result**:
   - ✅ Organizer's device receives push notification
   - ✅ Notification shows: "Event Approved"
   - ✅ Notification body shows event title
   - ✅ Tapping notification navigates to event detail

#### Test 2: Multiple Devices
1. Login as same organizer on 2 different devices
2. Trigger notification (admin approve event)
3. **Expected Result**:
   - ✅ Both devices receive notification
   - ✅ Check `fcm_tokens` table - should have 2 active tokens for same user

#### Test 3: Token Cleanup
1. Uninstall app from one device
2. Trigger notification
3. Check Edge Function logs
4. **Expected Result**:
   - ✅ Edge Function marks invalid token as inactive
   - ✅ In `fcm_tokens` table: old device token has `is_active = false`

## 🔍 Debugging

### Check FCM Token Registration

```sql
-- View all active tokens
SELECT 
  user_id, 
  token, 
  platform, 
  device_id,
  created_at,
  is_active
FROM fcm_tokens
WHERE is_active = true
ORDER BY created_at DESC;
```

### Check Notifications Table

```sql
-- View recent notifications
SELECT 
  id,
  user_id,
  type,
  title,
  body,
  is_read,
  created_at
FROM notifications
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;
```

### Manual Test Notification

```sql
-- Insert test notification manually
INSERT INTO notifications (user_id, type, title, body, data)
VALUES (
  '<your-user-id>',
  'test',
  'Test Notification',
  'This is a test notification from Supabase',
  '{"test": true}'::jsonb
);

-- This should trigger the Edge Function if setup correctly
```

### Check Edge Function Logs

```powershell
# Real-time logs
supabase functions logs send-push-notification --follow

# Recent logs
supabase functions logs send-push-notification --limit 50
```

### Debug Flutter Logs

Look for these debug messages in Flutter logs:

- `🔔 Firebase Messaging initialized`
- `📱 Notification permission: granted`
- `🎫 FCM Token: <token>`
- `✅ FCM token saved to database`
- `📬 Foreground message received`
- `✅ Local notification displayed`

## ⚠️ Common Issues

### Issue: No Sound or Vibration

**Cause**: Notification channel importance too low

**Solution**: Check AndroidManifest.xml has:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

### Issue: Notification Not Showing in Foreground

**Cause**: Local notification not being displayed

**Solution**: Check `_showForegroundNotification()` is called in `FirebaseMessaging.onMessage.listen()`

### Issue: Edge Function Error "Invalid Token"

**Cause**: Service Account JSON not set or incorrect

**Solution**:
```powershell
# Re-set the secret
$serviceAccount = Get-Content unp-art-space-firebase-adminsdk.json -Raw
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$serviceAccount"

# Verify secret is set
supabase secrets list
```

### Issue: FCM Token Not Saving to Database

**Cause**: RLS policies or authentication issue

**Solution**:
1. Make sure user is authenticated before calling `FirebaseMessagingService.initialize()`
2. Check RLS policies in `fcm_tokens` table allow INSERT for authenticated users

### Issue: "UNREGISTERED" Error in Logs

**Cause**: Device token is invalid (app uninstalled or token refreshed)

**Solution**: This is normal - Edge Function automatically marks token as inactive

## 📊 Success Criteria

- ✅ Notification permission granted on first launch
- ✅ FCM token saved to database
- ✅ Foreground notifications show with sound and heads-up display
- ✅ Background notifications appear in system tray
- ✅ Terminated app notifications launch app when tapped
- ✅ Event approval triggers organizer notification
- ✅ Multiple devices receive notifications
- ✅ Invalid tokens automatically marked inactive
- ✅ Notification tap navigates to correct screen

## 🚀 Next Steps

After basic notifications work:

1. **Navigation**: Implement deep linking based on notification type
2. **Grouping**: Bundle notifications by type
3. **Rich Notifications**: Add images and action buttons
4. **Custom Sounds**: Use different sounds for different notification types
5. **Notification Settings**: Let users customize notification preferences

## 📚 Documentation References

- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)
