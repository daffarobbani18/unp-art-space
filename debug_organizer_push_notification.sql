-- Debug: Cek FCM token untuk organizer
-- Cari organizer yang punya event

-- 1. Lihat semua organizer yang ada
SELECT 
  p.id as user_id,
  p.username,
  u.email,
  u.name,
  p.role,
  COUNT(e.id) as event_count
FROM profiles p
LEFT JOIN users u ON u.id = p.id
LEFT JOIN events e ON e.organizer_id = p.id
WHERE p.role = 'organizer'
GROUP BY p.id, p.username, u.email, u.name, p.role
ORDER BY event_count DESC;

-- 2. Cek FCM tokens organizer
SELECT 
  ft.user_id,
  p.username,
  u.email,
  u.name,
  ft.token,
  ft.platform,
  ft.is_active,
  ft.created_at,
  ft.updated_at
FROM fcm_tokens ft
JOIN profiles p ON p.id = ft.user_id
LEFT JOIN users u ON u.id = ft.user_id
WHERE p.role = 'organizer'
ORDER BY ft.updated_at DESC;

-- 3. Cek notifications yang sudah dibuat untuk organizer
SELECT 
  n.id,
  n.user_id,
  p.username,
  u.email,
  n.type,
  n.title,
  n.message,
  n.is_read,
  n.created_at
FROM notifications n
JOIN profiles p ON p.id = n.user_id
LEFT JOIN users u ON u.id = n.user_id
WHERE p.role = 'organizer'
ORDER BY n.created_at DESC
LIMIT 10;

-- 4. Test manual send push notification ke organizer (ganti user_id dengan organizer yang ada FCM token)
-- Uncomment dan jalankan jika organizer punya token
/*
SELECT send_push_notification_via_edge_function(
  'ORGANIZER_USER_ID_HERE'::uuid,
  'Test Push Organizer 🔔',
  'Testing push notification untuk organizer',
  '{"type": "test", "source": "manual_debug"}'::jsonb
);
*/
