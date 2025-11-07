# 🔧 FIX: Error 403 Unauthorized saat Upload Event

## 🔴 Error yang Terjadi:
```
Gagal mengupload event. StorageException(message: new row violates row-level security policy, statusCode: 403, error: Unauthorized)
```

## 📝 Penyebab:
Error ini terjadi karena **RLS (Row Level Security) Policy** di Supabase Storage bucket `artworks` tidak mengizinkan user untuk upload file.

## ✅ Solusi:

### **Langkah 1: Jalankan SQL di Supabase Dashboard**

1. Buka **Supabase Dashboard** → Project Anda
2. Klik **SQL Editor** di sidebar kiri
3. Klik **New Query**
4. Copy-paste SQL berikut:

```sql
-- ========================================
-- LANGKAH 1: Drop existing policies
-- ========================================
DROP POLICY IF EXISTS "Authenticated users can upload to artworks" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update their own files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete their own files" ON storage.objects;
DROP POLICY IF EXISTS "Public can read artworks" ON storage.objects;

-- ========================================
-- LANGKAH 2: Create new policies
-- ========================================

-- Policy A: Allow authenticated users to INSERT (upload)
CREATE POLICY "Authenticated users can upload to artworks"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'artworks'
);

-- Policy B: Allow authenticated users to UPDATE their own files
CREATE POLICY "Authenticated users can update their own files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'artworks' AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'artworks' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy C: Allow authenticated users to DELETE their own files
CREATE POLICY "Authenticated users can delete their own files"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'artworks' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy D: Allow public to read (SELECT)
CREATE POLICY "Public can read artworks"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'artworks'
);
```

5. Klik **Run** atau tekan `Ctrl + Enter`
6. Pastikan semua query berhasil (hijau ✅)

---

### **Langkah 2: Verifikasi Bucket Configuration**

1. Di Supabase Dashboard, klik **Storage** di sidebar
2. Klik bucket **`artworks`**
3. Pastikan **"Public bucket"** is **ON** (toggle ke kanan)
   
   Jika bucket belum public, klik toggle untuk enable.

---

### **Langkah 3: Test Upload**

1. Restart aplikasi Flutter:
   ```bash
   # Stop app dengan Ctrl+C
   # Kemudian run lagi:
   flutter run
   ```

2. Login sebagai **artist**
3. Klik FAB → **Ajukan Event**
4. Isi form lengkap dan upload gambar
5. Klik **Upload Event**

**Expected Result:** ✅ Event berhasil diupload!

---

## 🔍 Troubleshooting Tambahan:

### Jika masih error 403:

#### **Option A: Gunakan Policy Super Permissive (Development Only)**
```sql
-- Drop existing policies
DROP POLICY IF EXISTS "Authenticated users can upload to artworks" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update their own files" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete their own files" ON storage.objects;
DROP POLICY IF EXISTS "Public can read artworks" ON storage.objects;

-- Create super permissive policies
CREATE POLICY "Allow all authenticated INSERT" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'artworks');

CREATE POLICY "Allow all authenticated UPDATE" ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id = 'artworks')
WITH CHECK (bucket_id = 'artworks');

CREATE POLICY "Allow all authenticated DELETE" ON storage.objects
FOR DELETE TO authenticated
USING (bucket_id = 'artworks');

CREATE POLICY "Allow all SELECT" ON storage.objects
FOR SELECT TO public
USING (bucket_id = 'artworks');
```

**⚠️ WARNING:** Policy ini sangat permissive dan **TIDAK direkomendasikan untuk production**. Gunakan hanya untuk development/testing.

---

#### **Option B: Disable RLS Temporarily (Testing Only)**
```sql
-- DANGER: Only for testing!
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
```

**⚠️ WARNING:** Ini sangat **TIDAK AMAN**! Jangan gunakan di production. Enable kembali setelah testing:
```sql
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

---

#### **Option C: Check Bucket Existence**
```sql
-- Check if bucket exists
SELECT id, name, public FROM storage.buckets WHERE name = 'artworks';

-- If not exists, create it:
INSERT INTO storage.buckets (id, name, public) 
VALUES ('artworks', 'artworks', true);

-- Make sure it's public:
UPDATE storage.buckets SET public = true WHERE name = 'artworks';
```

---

## 📊 Verification Queries:

Setelah menjalankan fix, verifikasi dengan query ini:

```sql
-- Check all storage policies for artworks bucket
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd
FROM pg_policies
WHERE tablename = 'objects' AND policyname LIKE '%artwork%';

-- Check storage policies via storage schema
SELECT * FROM storage.policies WHERE bucket_id = 'artworks';

-- Expected result: You should see 4 policies:
-- 1. Authenticated users can upload to artworks (INSERT)
-- 2. Authenticated users can update their own files (UPDATE)
-- 3. Authenticated users can delete their own files (DELETE)
-- 4. Public can read artworks (SELECT)
```

---

## 🎯 Summary:

**Yang Sudah Diperbaiki:**
- ✅ Simplified storage path dari `events/{user_id}/{filename}` menjadi `{user_id}/{filename}`
- ✅ Added `upsert: true` untuk menghindari conflict
- ✅ Enhanced error handling dengan pesan yang lebih jelas
- ✅ Created SQL file untuk fix RLS policies

**Yang Perlu Dilakukan User:**
1. ✅ Jalankan SQL di Supabase Dashboard
2. ✅ Pastikan bucket `artworks` is public
3. ✅ Test upload event
4. ✅ Jika masih error, coba Option A (super permissive) untuk development

---

## 📞 Jika Masih Bermasalah:

1. **Check Supabase Logs:**
   - Dashboard → Logs → Storage logs
   - Lihat detail error message

2. **Check Console Output:**
   - Lihat Flutter console untuk log emoji:
     - 📤 Uploading to storage path...
     - ✅ Upload successful
     - ❌ Storage error...

3. **Verify User Authentication:**
   ```dart
   final user = Supabase.instance.client.auth.currentUser;
   print('Current user ID: ${user?.id}');
   ```

Semoga berhasil! 🚀
