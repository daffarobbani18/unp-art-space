# 🔧 Panduan Memperbaiki Admin Dashboard - Data Tidak Muncul

## 🎯 Masalah
- Admin dashboard menampilkan 0 artwork
- Debug button menunjukkan data kosong
- Upload dari artist berhasil tapi tidak terlihat di admin

## 🔍 Penyebab
1. **Row Level Security (RLS)** di Supabase memblokir query dari admin karena tidak ada policy yang mengizinkan admin untuk membaca tabel `artworks` dan `users`.
2. **Status tidak konsisten**: Database masih menggunakan status bahasa Indonesia (`disetujui`, `menunggu_persetujuan`, `ditolak`) sedangkan kode aplikasi sudah update ke bahasa Inggris (`approved`, `pending`, `rejected`).

---

## ✅ Solusi (Step by Step)

### **Step 1: Buka Supabase Dashboard**
1. Login ke https://supabase.com
2. Pilih project Anda: `vepmvxiddwmpetxfdwjn`
3. Klik menu **SQL Editor** di sidebar kiri

### **Step 2: Jalankan SQL Fix**
1. Di SQL Editor, klik **New Query**
2. Copy seluruh isi file `supabase_rls_fix.sql` 
3. Paste di SQL Editor
4. Klik tombol **Run** (atau tekan Ctrl+Enter)
5. Tunggu sampai muncul notifikasi "Success"

⚠️ **PENTING:** SQL ini juga akan mengupdate status lama ke format baru:
- `disetujui` → `approved`
- `menunggu_persetujuan` → `pending`
- `ditolak` → `rejected`

### **Step 3: Verifikasi di Supabase**
Jalankan query verification (ada di bagian bawah file SQL):

```sql
-- Cek total artworks per status
SELECT status, COUNT(*) as total
FROM public.artworks
GROUP BY status
ORDER BY status;
```

**Hasil yang diharapkan:**
```
status   | total
---------|------
approved | X
pending  | Y
rejected | Z
```

Jika hasilnya kosong, berarti memang belum ada data artwork yang di-upload.

### **Step 4: Pastikan User Admin Ada**
```sql
-- Cek user admin
SELECT id, name, email, role
FROM public.users
WHERE role = 'admin';
```

**Jika kosong**, Anda perlu membuat user admin:
1. Register akun baru di aplikasi mobile
2. Kemudian update role-nya di Supabase:

```sql
-- Ganti 'admin@example.com' dengan email Anda
UPDATE public.users 
SET role = 'admin' 
WHERE email = 'admin@example.com';
```

### **Step 5: Test di Admin Dashboard**
1. Jalankan admin app:
   ```powershell
   flutter run -d chrome --target=lib/main/main_admin.dart
   ```

2. Login dengan akun admin

3. Buka menu **Moderasi**

4. Klik tombol **Debug** (orange button)
   - Seharusnya sekarang menampilkan data artwork

5. Lihat tab **Pending**
   - Artwork dengan status pending akan muncul

### **Step 6: Test Upload dari Artist**
1. Buka aplikasi mobile (artist)
2. Upload artwork baru
3. Refresh halaman moderasi admin
4. Artwork baru akan muncul di tab Pending
5. Klik **Setujui** → artwork pindah ke tab Approved

---

## 🔎 Troubleshooting

### **Problem: Masih 0 setelah jalankan SQL**
**Cek 1:** Apakah status sudah terupdate?
```sql
-- Lihat semua unique status yang ada
SELECT DISTINCT status FROM public.artworks;
```
Harusnya hanya ada: `approved`, `pending`, `rejected`

Jika masih ada status lama (`disetujui`, `menunggu_persetujuan`, `ditolak`), jalankan lagi:
```sql
UPDATE public.artworks SET status = 'approved' WHERE status = 'disetujui';
UPDATE public.artworks SET status = 'pending' WHERE status IN ('menunggu_persetujuan', 'menunggu');
UPDATE public.artworks SET status = 'rejected' WHERE status = 'ditolak';
```

**Cek 2:** Apakah SQL berhasil tanpa error?
- Scroll ke bawah di SQL Editor, lihat apakah ada error merah
- Jika ada error tentang "policy already exists", sudah benar (policy duplicate dihapus lalu dibuat ulang)

**Cek 2:** Apakah Anda login sebagai admin yang benar?
```sql
-- Cek user yang sedang login (di app)
SELECT auth.uid(), u.email, u.role
FROM public.users u
WHERE u.id = auth.uid();
```

**Cek 3:** Apakah ada data artwork di database?
```sql
SELECT COUNT(*) FROM public.artworks;
```

### **Problem: Error "relation public.users does not exist"**
Berarti tabel `users` belum dibuat. Pastikan Anda sudah:
1. Register minimal 1 user di aplikasi mobile
2. Cek di Supabase → Table Editor → Apakah tabel `users` ada?

### **Problem: Artist tidak bisa upload**
Pastikan user memiliki role 'artist':
```sql
-- Ganti 'artist@example.com' dengan email artist
UPDATE public.users 
SET role = 'artist' 
WHERE email = 'artist@example.com';
```

---

## 📊 Struktur RLS yang Benar

Setelah menjalankan SQL fix, struktur policy Anda akan seperti ini:

### **Tabel: artworks**
| Policy | Role | Action | Condition |
|--------|------|--------|-----------|
| admin_select_artworks | Admin | SELECT | Baca semua artwork |
| admin_update_artworks | Admin | UPDATE | Update semua artwork |
| admin_delete_artworks | Admin | DELETE | Hapus semua artwork |
| artist_insert_own_artwork | Artist | INSERT | Insert artwork sendiri |
| artist_select_own_artworks | Artist | SELECT | Baca artwork sendiri |
| public_select_approved_artworks | All | SELECT | Baca artwork approved |

### **Tabel: users**
| Policy | Role | Action | Condition |
|--------|------|--------|-----------|
| admin_select_users | Admin | SELECT | Baca semua user |
| user_select_self | User | SELECT | Baca profil sendiri |

---

## 🎉 Hasil Akhir yang Diharapkan

✅ **Admin Dashboard:**
- Tab Moderasi menampilkan artwork pending
- Statistik dashboard menunjukkan angka yang benar
- Bisa approve/reject artwork
- Bisa lihat nama artist

✅ **Artist App:**
- Bisa upload artwork (status: pending)
- Artwork langsung muncul di admin dashboard
- Setelah approved, muncul di home page

✅ **User App:**
- Home page menampilkan artwork yang sudah approved
- Tidak bisa lihat artwork pending/rejected

---

## 📞 Jika Masih Bermasalah

Kirimkan screenshot dari:
1. Hasil query verification di Supabase
2. Console log saat buka halaman moderasi admin
3. Hasil klik tombol Debug di admin dashboard

Saya akan bantu troubleshoot lebih lanjut! 🚀
