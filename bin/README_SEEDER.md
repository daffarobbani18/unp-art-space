# 🌱 Database Seeder - Campus Art Space

Script untuk mengisi database dengan data dummy untuk testing dan development.

## 📋 Prerequisites

1. **Install Dependencies:**

```bash
flutter pub add supabase
flutter pub add faker
```

Atau tambahkan ke `pubspec.yaml`:

```yaml
dependencies:
  supabase: ^2.9.1
  faker: ^2.2.0
```

2. **Dapatkan Service Role Key:**
   - Login ke [Supabase Dashboard](https://supabase.com/dashboard)
   - Pilih project Anda
   - Go to **Settings** → **API**
   - Copy **service_role** key (bukan anon key!)

## 🚀 Cara Menggunakan

### 1. Update Konfigurasi

Buka file `bin/seed_database.dart` dan update:

```dart
const String SUPABASE_URL = 'https://vepmvxiddwmpetxfdwjn.supabase.co';
const String SERVICE_ROLE_KEY = 'YOUR_SERVICE_ROLE_KEY_HERE'; // ⚠️ GANTI INI!
```

### 2. Jalankan Script

Dari root project:

```bash
dart run bin/seed_database.dart
```

## 📊 Data Yang Dibuat

### 👥 Users (4 Akun)

| Email | Password | Role | Purpose |
|-------|----------|------|---------|
| `admin@campus.art` | `admin123` | Admin | Moderasi konten |
| `organizer@campus.art` | `organizer123` | Organizer | Membuat event |
| `artist@campus.art` | `artist123` | Artist | Upload artwork |
| `viewer@campus.art` | `viewer123` | Viewer | Like & comment |

### 🎨 Content

- ✅ **3 Events** (status: open) by Organizer
- ✅ **10 Artworks** by Artist
  - 7 approved (dapat dilihat publik)
  - 3 pending (menunggu admin approval)
- ✅ **3 Event Submissions** (artwork → event)
- ✅ **7 Likes** dari Viewer
- ✅ **~3-4 Comments** dari Viewer
- ✅ **2 Artist Follows**

## 🔄 Proses Seeding

Script berjalan dalam 5 tahap:

### 1️⃣ Cleanup
```
🧹 Menghapus data lama dengan urutan aman:
   event_submissions → comments → likes → artist_follows
   → artworks → events → users → profiles
```

### 2️⃣ Seed Users
```
👥 Membuat 4 user dengan role berbeda
   - Create auth user via admin API
   - Insert ke tabel profiles
   - Insert ke tabel users (extended data)
```

### 3️⃣ Generate Content
```
🎨 Organizer membuat 3 event
   Artist upload 10 artwork (status: pending)
```

### 4️⃣ Admin Verification
```
🛡️ Admin approve 7 dari 10 artwork
   3 artwork tetap pending untuk simulasi antrian
```

### 5️⃣ Interactions
```
💬 Viewer like & comment artwork yang approved
   Artist submit 3 artwork ke event pertama
   Viewer & Organizer follow Artist
```

## 📝 Output Log

Contoh output saat script berjalan:

```
🚀 Starting Database Seeding...

🧹 Step 1: Cleaning up old data...
  - Deleting event_submissions...
  - Deleting comments...
  - Deleting likes...
  - Deleting artist_follows...
  - Deleting artworks...
  - Deleting events...
  - Deleting users...
  - Deleting profiles...
✅ Cleanup completed!

👥 Step 2: Creating users...
  ✓ Admin created: admin@campus.art
  ✓ Organizer created: organizer@campus.art
  ✓ Artist created: artist@campus.art
  ✓ Viewer created: viewer@campus.art
✅ Users created successfully!

🎨 Step 3: Creating content...
  📅 Creating events...
    ✓ Event created: Campus Art Exhibition 2025
    ✓ Event created: Digital Art Showcase
    ✓ Event created: Contemporary Art Fair
  🖼️  Creating artworks...
    ✓ Created 10 artworks (all pending approval)
✅ Content created successfully!

🛡️  Step 4: Admin verification process...
  ✓ Approved 7 artworks
  ✓ 3 artworks remain pending
✅ Admin verification completed!

💬 Step 5: Creating interactions...
  📝 Creating event submissions...
    ✓ Submitted 3 artworks to event
  👍 Creating likes and comments...
    ✓ Created 7 likes
    ✓ Created 4 comments
  🔗 Creating artist follows...
    ✓ Created 2 follows
✅ Interactions created successfully!

✅ Database seeding completed successfully!
```

## 🧪 Testing Setelah Seeding

### Login Test

Gunakan credentials ini untuk testing:

```dart
// Admin Dashboard
email: admin@campus.art
password: admin123

// Organizer Panel
email: organizer@campus.art
password: organizer123

// Artist Mobile App
email: artist@campus.art
password: artist123

// Viewer Mobile App
email: viewer@campus.art
password: viewer123
```

### Verifikasi Data

1. **Login sebagai Viewer** → Lihat 7 artwork yang approved
2. **Login sebagai Artist** → Lihat 10 artwork (7 approved + 3 pending)
3. **Login sebagai Admin** → Lihat 3 pending artwork di dashboard
4. **Login sebagai Organizer** → Lihat 3 event & submissions

## ⚠️ Warning

**⚠️ SERVICE ROLE KEY SANGAT BERBAHAYA!**

- Jangan commit ke Git!
- Jangan share ke orang lain!
- Service Role Key bypass semua RLS (Row Level Security)
- Hanya gunakan untuk development/testing!

## 🔧 Customization

### Mengubah Jumlah Data

Edit di file `seed_database.dart`:

```dart
// Jumlah events (default: 3)
for (var i = 0; i < 3; i++) { ... }

// Jumlah artworks (default: 10)
for (var i = 0; i < 10; i++) { ... }

// Jumlah approved (default: 7 dari 10)
final artworksToApprove = artworkIds.take(7).toList();
```

### Menambah User Baru

```dart
final newUserId = await createUser(
  email: 'newuser@campus.art',
  password: 'password123',
  role: 'artist',
  name: 'New Artist',
  bio: 'Talented new artist',
);
```

## 🐛 Troubleshooting

### Error: "Invalid API key"
- ✅ Pastikan menggunakan **service_role** key, bukan anon key
- ✅ Check di Supabase Dashboard → Settings → API

### Error: "Foreign key constraint"
- ✅ Jalankan cleanup lagi dengan urutan yang benar
- ✅ Pastikan tidak ada data orphan

### Error: "User already exists"
- ✅ Jalankan cleanup terlebih dahulu
- ✅ Atau hapus manual user di Supabase Dashboard → Authentication

## 📚 Resources

- [Supabase Admin API](https://supabase.com/docs/reference/dart/admin-api)
- [Faker Package](https://pub.dev/packages/faker)
- [Database Schema](../schema.sql)

---

<div align="center">

**Happy Seeding! 🌱**

</div>
