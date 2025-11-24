# 📋 PANDUAN UPDATE REGISTRASI - ROLE ORGANIZER

## 🎯 Ringkasan Perubahan

Registrasi sekarang mendukung **3 Role**:
1. **Viewer** - Penikmat Seni
2. **Artist** - Kreator Karya (dengan spesialisasi)
3. **Organizer** - Event Organizer/Panitia ✨ **BARU!**

---

## 🚀 Langkah Deployment

### 1️⃣ Update Database (WAJIB!)

**Buka Supabase Dashboard** → SQL Editor → **Jalankan file:**
```
supabase_update_organizer_support.sql
```

File ini akan:
- ✅ Update trigger `handle_new_user()` untuk support role organizer
- ✅ Pastikan constraint role di tabel `profiles` sudah benar
- ✅ Verifikasi trigger aktif pada tabel `users`

**Query Verifikasi:**
```sql
-- Cek trigger aktif
SELECT trigger_name, event_object_table, action_timing
FROM information_schema.triggers
WHERE trigger_name = 'on_users_insert';

-- Cek constraint role
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.profiles'::regclass
  AND conname LIKE '%role%';
```

---

### 2️⃣ Update Kode Flutter (SUDAH SELESAI ✅)

File `register_page.dart` sudah diupdate dengan:

#### ✨ **Fitur Baru:**

**A. Enum UserRole**
```dart
enum UserRole { artist, viewer, organizer }
```

**B. UI Role Selection (3 Kolom)**
```dart
Row(
  children: [
    Expanded(child: _buildCustomRadioTile(
      value: UserRole.viewer,
      label: 'Viewer',
      subtitle: 'Penikmat Seni',
      icon: Icons.visibility_outlined,
    )),
    Expanded(child: _buildCustomRadioTile(
      value: UserRole.artist,
      label: 'Artist',
      subtitle: 'Kreator Karya',
      icon: Icons.palette_outlined,
    )),
    Expanded(child: _buildCustomRadioTile(
      value: UserRole.organizer,
      label: 'Organizer',
      subtitle: 'Panitia Event',
      icon: Icons.event_outlined,
    )),
  ],
)
```

**C. Kirim Metadata ke Supabase Auth**
```dart
final authResponse = await supabase.auth.signUp(
  email: userEmail,
  password: password,
  data: {
    'full_name': userName,
    'role': roleString, // 'viewer' / 'artist' / 'organizer'
    'username': userName,
  },
);
```

**D. Navigasi Otomatis Sesuai Role**
```dart
if (roleString == 'organizer') {
  Navigator.of(context).pushReplacementNamed('/organizer_home');
} else {
  Navigator.of(context).pushReplacementNamed('/home');
}
```

---

## 🔄 Alur Registrasi Lengkap

```
┌─────────────────────────────────────────────────────────────┐
│  1. USER MENGISI FORM                                       │
│     - Nama, Email, Password                                 │
│     - Pilih Role: Viewer / Artist / Organizer              │
│     - (Jika Artist) Pilih Spesialisasi                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  2. SUPABASE AUTH (auth.users)                              │
│     await supabase.auth.signUp(                             │
│       email: email,                                         │
│       password: password,                                   │
│       data: { 'role': 'organizer', ... }                    │
│     )                                                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  3. INSERT KE TABEL USERS (public.users)                    │
│     await supabase.from('users').insert({                   │
│       'id': user.id,                                        │
│       'role': 'organizer',                                  │
│       'name': userName,                                     │
│       ...                                                   │
│     })                                                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  4. TRIGGER OTOMATIS (public.profiles)                      │
│     ✨ TRIGGER: on_users_insert                             │
│     ✨ FUNCTION: handle_new_user()                          │
│                                                             │
│     INSERT INTO profiles (id, role, username)               │
│     VALUES (user.id, 'organizer', userName)                 │
│     ON CONFLICT (id) DO UPDATE ...                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  5. NAVIGASI OTOMATIS                                       │
│     if (role == 'organizer')                                │
│       → Navigator.pushReplacementNamed('/organizer_home')   │
│     else                                                    │
│       → Navigator.pushReplacementNamed('/home')             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Tabel Database

### **public.users**
```sql
id              uuid PRIMARY KEY
created_at      timestamp
name            text
email           text UNIQUE
role            text DEFAULT 'viewer'  -- viewer/artist/organizer
specialization  text                   -- Hanya untuk artist
bio             text
social_media    jsonb
profile_image_url text
```

### **public.profiles**
```sql
id          uuid PRIMARY KEY
created_at  timestamp
role        text CHECK (role IN ('admin', 'artist', 'viewer', 'organizer'))
username    text

-- Foreign Keys:
CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
```

**⚠️ PENTING:** Trigger akan otomatis sinkronkan data dari `users` ke `profiles`!

---

## 🧪 Testing

### Test Case 1: Registrasi sebagai Viewer
1. Buka halaman registrasi
2. Pilih role **Viewer**
3. Isi nama, email, password
4. Klik **Daftar**
5. ✅ Harus masuk ke `/home`

### Test Case 2: Registrasi sebagai Artist
1. Pilih role **Artist**
2. Pilih spesialisasi (contoh: Pelukis)
3. Isi data lengkap
4. Klik **Daftar**
5. ✅ Harus masuk ke `/home`

### Test Case 3: Registrasi sebagai Organizer ✨
1. Pilih role **Organizer**
2. Isi data lengkap
3. Klik **Daftar**
4. ✅ Harus masuk ke `/organizer_home`

### Verifikasi Database:
```sql
-- Cek data di auth.users
SELECT id, email, raw_user_meta_data 
FROM auth.users 
WHERE email = 'test@organizer.com';

-- Cek data di public.users
SELECT id, name, email, role 
FROM public.users 
WHERE email = 'test@organizer.com';

-- Cek data di public.profiles (HARUS ADA!)
SELECT id, role, username 
FROM public.profiles 
WHERE id = (SELECT id FROM auth.users WHERE email = 'test@organizer.com');
```

**Expected Result:**
- ✅ Data ada di ketiga tabel
- ✅ Role konsisten: 'organizer' di semua tabel
- ✅ Username terisi dari nama user

---

## 🎨 UI/UX Improvements

### Before (2 Role):
```
┌─────────────┬─────────────┐
│   Viewer    │   Artist    │
└─────────────┴─────────────┘
```

### After (3 Role):
```
┌──────────┬──────────┬──────────┐
│  Viewer  │  Artist  │Organizer │
│ Penikmat │ Kreator  │  Panitia │
│   Seni   │  Karya   │   Event  │
└──────────┴──────────┴──────────┘
```

**Desain:**
- ✨ Glass morphism style
- 🎨 Purple accent untuk selected state
- 📱 Responsive 3-column layout
- 🏷️ Subtitle untuk menjelaskan role

---

## 🔧 Troubleshooting

### Problem 1: Error "role not in check constraint"
**Solusi:**
```sql
-- Update constraint di profiles
ALTER TABLE public.profiles
DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
ADD CONSTRAINT profiles_role_check 
CHECK (role = ANY (ARRAY['admin', 'artist', 'viewer', 'organizer']));
```

### Problem 2: Trigger tidak jalan
**Solusi:**
```sql
-- Hapus dan buat ulang trigger
DROP TRIGGER IF EXISTS on_users_insert ON public.users;

CREATE TRIGGER on_users_insert
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

### Problem 3: Data tidak masuk ke profiles
**Debug:**
```sql
-- Cek apakah trigger aktif
SELECT * FROM information_schema.triggers 
WHERE trigger_name = 'on_users_insert';

-- Cek apakah function ada
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

-- Test manual insert
INSERT INTO public.users (id, name, email, role)
VALUES (gen_random_uuid(), 'Test', 'test@test.com', 'organizer');

-- Check di profiles
SELECT * FROM public.profiles 
WHERE username = 'Test';
```

---

## ✅ Checklist Deployment

- [ ] Jalankan `supabase_update_organizer_support.sql` di Supabase
- [ ] Verifikasi trigger aktif (query verifikasi)
- [ ] Verifikasi constraint role sudah benar
- [ ] Test registrasi Viewer → masuk ke `/home`
- [ ] Test registrasi Artist → masuk ke `/home`
- [ ] Test registrasi Organizer → masuk ke `/organizer_home`
- [ ] Cek data di tabel `users` dan `profiles` sinkron
- [ ] Test error handling (email duplicate, password lemah)

---

## 📚 File yang Diubah

1. ✅ `lib/app/Features/auth/screens/register_page.dart`
   - Tambah enum `organizer`
   - Update UI 3 kolom
   - Kirim metadata ke auth
   - Navigasi otomatis

2. ✅ `supabase_update_organizer_support.sql` (BARU)
   - Update trigger function
   - Support role organizer
   - Query verifikasi

3. ✅ `supabase_fix_profiles_fk.sql` (UPDATED)
   - Sudah ada dari sebelumnya
   - Masih bisa digunakan untuk fix FK constraint

---

## 🎉 Selesai!

Sistem registrasi sekarang sudah mendukung role **Organizer**! 

**Next Steps:**
- Implementasi fitur Event Management di `/organizer_home`
- Tambah permissions untuk organizer di RLS policies
- Buat dashboard organizer yang lengkap

Happy Coding! 🚀
