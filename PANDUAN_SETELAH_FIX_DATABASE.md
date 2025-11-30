# Panduan Setelah Perbaikan Database

## ✅ Yang Sudah Diperbaiki
1. **Foreign Key**: `users.id` → `auth.users(id)` 
2. **Sinkronisasi**: Data profiles ↔ users sudah sama
3. **View**: `user_profiles` untuk query gabungan
4. **Trigger**: Auto-sync role dari profiles ke users

## 📋 Update Kode Flutter

### 1. Gunakan View `user_profiles` untuk Query
```dart
// BEFORE (query 2 tabel terpisah)
final profile = await supabase.from('profiles').select('role').eq('id', userId).single();
final user = await supabase.from('users').select('email, name').eq('id', userId).single();

// AFTER (gunakan view)
final data = await supabase
  .from('user_profiles')
  .select('role, email, name, username, bio, profile_image_url')
  .eq('id', userId)
  .single();
```

### 2. Single Source of Truth untuk Role
- **profiles.role** = Master (linked ke auth.users)
- **users.role** = Mirror (auto-sync via trigger)
- Selalu ambil role dari `profiles` atau `user_profiles` view

### 3. Register User Flow
```dart
// 1. Supabase Auth (otomatis create profiles via trigger)
await supabase.auth.signUp(email: email, password: password);

// 2. Insert ke users (data tambahan)
await supabase.from('users').insert({
  'id': userId,
  'email': email,
  'name': name,
  'role': role, // Akan auto-sync ke profiles
});
```

## 🧪 Testing Checklist

### Test 1: Login Multi-User (FCM Token)
- [ ] Login Artist → FCM token saved
- [ ] Logout Artist
- [ ] Login Organizer (same device) → Token user_id updated
- [ ] Check database: `SELECT * FROM fcm_tokens WHERE token = 'YOUR_TOKEN'`
- [ ] Result: user_id harus = organizer ID

### Test 2: Push Notification
- [ ] Artist upload artwork → Admin approve → Push muncul di Artist ✅
- [ ] Organizer create event → Admin approve → Push muncul di Organizer ✅
- [ ] Artist submit to event → Push muncul di Organizer ✅

### Test 3: Data Konsistensi
```sql
-- Cek apakah role sinkron
SELECT 
  p.id,
  p.role as profile_role,
  u.role as user_role,
  u.email
FROM profiles p
JOIN users u ON u.id = p.id
WHERE p.role != u.role; -- Harus kosong!
```

## 🔍 Debug Query

```sql
-- 1. Lihat FCM token per user dengan detail lengkap
SELECT 
  ft.token,
  ft.platform,
  ft.is_active,
  up.email,
  up.name,
  up.role,
  up.username
FROM fcm_tokens ft
JOIN user_profiles up ON up.id = ft.user_id
ORDER BY ft.updated_at DESC;

-- 2. Cek notifications untuk organizer
SELECT 
  n.title,
  n.message,
  n.type,
  n.is_read,
  up.email,
  up.role,
  n.created_at
FROM notifications n
JOIN user_profiles up ON up.id = n.user_id
WHERE up.role = 'organizer'
ORDER BY n.created_at DESC;

-- 3. Test manual push ke organizer
SELECT send_push_notification_via_edge_function(
  (SELECT id FROM profiles WHERE role = 'organizer' LIMIT 1),
  'Test Organizer Push 🔔',
  'Testing push notification untuk organizer',
  '{"type": "test"}'::jsonb
);
```

## ⚠️ Breaking Changes?
**TIDAK ADA!** Karena:
- Kode lama tetap bisa query `profiles` dan `users` terpisah
- View `user_profiles` hanya tambahan untuk kemudahan
- Trigger hanya sync, tidak mengubah behavior

## 🚀 Next Steps
1. ✅ Jalankan `fix_users_profiles_sync.sql`
2. ✅ Verifikasi hasil dengan query di bagian 5
3. ✅ Test login Artist → Organizer di HP
4. ✅ Test push notification
5. ⏳ (Opsional) Refactor kode untuk pakai view `user_profiles`
