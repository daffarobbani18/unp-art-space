# 📦 Supabase Storage - Event Banners Setup

## ✅ Storage Bucket Configuration

### **Bucket Name:** `event_banners`

**Settings:**
- ✅ **Public Access**: Enabled (untuk read)
- ✅ **Allowed MIME Types**: 
  - `image/jpeg`
  - `image/png`
  - `image/webp`
  - `image/jpg`
- ✅ **Max File Size**: 5 MB
- ✅ **Path**: `event_banners/{filename}`

---

## 🔐 Row Level Security (RLS) Policies

### **1. Public Access Banner** (SELECT)
**Fungsi:** Mengizinkan semua orang (termasuk guest) untuk melihat/membaca banner event

```sql
CREATE POLICY "Public Access Banner"
ON storage.objects FOR SELECT
USING ( bucket_id = 'event_banners' );
```

**Penjelasan:**
- Policy ini memungkinkan public URL untuk banner event
- User tidak perlu authentication untuk view gambar
- Cocok untuk share event ke social media

---

### **2. Organizer Upload Banner** (INSERT)
**Fungsi:** Mengizinkan organizer yang sudah login untuk upload banner baru

```sql
CREATE POLICY "Organizer Upload Banner"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'event_banners' AND
  auth.role() = 'authenticated'
);
```

**Penjelasan:**
- Hanya authenticated user yang bisa upload
- Tidak perlu cek role='organizer' karena sudah dihandle di app level
- Upload akan otomatis mencatat `owner` = `auth.uid()`

---

### **3. Organizer Manage Own Banner** (UPDATE)
**Fungsi:** Organizer hanya bisa update banner milik mereka sendiri

```sql
CREATE POLICY "Organizer Manage Own Banner"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'event_banners' AND
  auth.uid() = owner
);
```

**Penjelasan:**
- `auth.uid() = owner` memastikan organizer hanya edit file mereka
- Mencegah organizer A mengedit banner organizer B
- Update bisa untuk metadata atau replace file

---

### **4. Organizer Delete Own Banner** (DELETE)
**Fungsi:** Organizer hanya bisa delete banner milik mereka sendiri

```sql
CREATE POLICY "Organizer Delete Own Banner"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'event_banners' AND
  auth.uid() = owner
);
```

**Penjelasan:**
- Safety mechanism untuk prevent accidental/malicious deletion
- Owner field otomatis di-set saat upload
- Penting untuk cleanup saat event dihapus

---

## 📊 Storage Workflow

### **Upload Flow:**
```
1. User (Organizer) pilih gambar dari device
   ↓
2. Compress/resize gambar (optional, recommended)
   ↓
3. Generate unique filename: {uuid}.{extension}
   ↓
4. Upload ke storage.upload('event_banners/{filename}', file)
   ↓ (Policy: Organizer Upload Banner)
5. Get public URL: storage.getPublicUrl('event_banners/{filename}')
   ↓
6. Save URL ke database (events.image_url)
```

### **View Flow:**
```
1. Frontend request image_url dari database
   ↓
2. Display dengan Image.network(image_url)
   ↓ (Policy: Public Access Banner)
3. Supabase serve image langsung (no auth needed)
```

### **Delete Flow:**
```
1. User delete event dari dashboard
   ↓
2. Extract filename dari image_url
   ↓
3. Delete dari storage.remove(['event_banners/{filename}'])
   ↓ (Policy: Organizer Delete Own Banner)
4. Delete event record dari database
```

---

## 🔧 Flutter Implementation

### **1. Upload Image**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

Future<String?> uploadEventBanner(File imageFile) async {
  try {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'event_banners/$fileName';
    
    // Upload file
    await Supabase.instance.client.storage
        .from('event_banners')
        .upload(path, imageFile);
    
    // Get public URL
    final publicUrl = Supabase.instance.client.storage
        .from('event_banners')
        .getPublicUrl(path);
    
    return publicUrl;
  } catch (e) {
    debugPrint('Upload error: $e');
    return null;
  }
}
```

### **2. Delete Image**
```dart
Future<void> deleteEventBanner(String imageUrl) async {
  try {
    // Extract path from URL
    final uri = Uri.parse(imageUrl);
    final path = uri.pathSegments.skip(4).join('/'); // event_banners/filename.jpg
    
    // Delete from storage
    await Supabase.instance.client.storage
        .from('event_banners')
        .remove([path]);
  } catch (e) {
    debugPrint('Delete error: $e');
  }
}
```

### **3. Display Image**
```dart
// Automatic caching dengan NetworkImage
Image.network(
  imageUrl,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error);
  },
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator();
  },
)
```

---

## 📝 Best Practices

### **1. Naming Convention**
```dart
// ✅ Good: Unique with timestamp
final fileName = '${DateTime.now().millisecondsSinceEpoch}_${uuid.v4()}.jpg';

// ❌ Bad: User input (dapat duplikat)
final fileName = '${eventTitle}.jpg';
```

### **2. File Size Optimization**
```dart
import 'package:image/image.dart' as img;

Future<File> compressImage(File file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  
  // Resize jika terlalu besar
  final resized = img.copyResize(image!, width: 1200);
  
  // Compress dengan quality 85%
  final compressed = img.encodeJpg(resized, quality: 85);
  
  // Save to temp file
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/compressed.jpg');
  await tempFile.writeAsBytes(compressed);
  
  return tempFile;
}
```

### **3. Error Handling**
```dart
try {
  final url = await uploadEventBanner(file);
  if (url == null) throw Exception('Upload failed');
  // Success
} on StorageException catch (e) {
  if (e.statusCode == '413') {
    // File too large
    showError('Ukuran file maksimal 5MB');
  } else if (e.statusCode == '415') {
    // Unsupported media type
    showError('Format file tidak didukung');
  } else {
    showError('Gagal upload: ${e.message}');
  }
} catch (e) {
  showError('Terjadi kesalahan');
}
```

### **4. Cleanup on Delete**
```dart
Future<void> deleteEvent(String eventId, String? imageUrl) async {
  try {
    // 1. Delete from storage first
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await deleteEventBanner(imageUrl);
    }
    
    // 2. Then delete from database
    await Supabase.instance.client
        .from('events')
        .delete()
        .eq('id', eventId);
    
  } catch (e) {
    debugPrint('Delete event error: $e');
    rethrow;
  }
}
```

---

## 🔍 Verification Queries

### **Check Storage Policies:**
```sql
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'objects' 
  AND schemaname = 'storage';
```

### **List All Banners:**
```sql
SELECT 
    name,
    bucket_id,
    owner,
    created_at,
    metadata->>'size' as file_size,
    metadata->>'mimetype' as mime_type
FROM storage.objects
WHERE bucket_id = 'event_banners'
ORDER BY created_at DESC;
```

### **Check Storage Usage:**
```sql
SELECT 
    bucket_id,
    COUNT(*) as total_files,
    SUM((metadata->>'size')::bigint) as total_size_bytes,
    SUM((metadata->>'size')::bigint) / 1024 / 1024 as total_size_mb
FROM storage.objects
WHERE bucket_id = 'event_banners'
GROUP BY bucket_id;
```

---

## 🚨 Common Issues & Solutions

### **Issue 1: "Storage Error: Unauthorized"**
**Cause:** User belum authenticated atau policy salah

**Solution:**
```dart
// Pastikan user sudah login
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  throw Exception('Please login first');
}
```

### **Issue 2: "File too large"**
**Cause:** File > 5MB

**Solution:**
```dart
// Check size sebelum upload
final fileSize = await file.length();
if (fileSize > 5 * 1024 * 1024) {
  // Compress atau reject
  throw Exception('File size must be less than 5MB');
}
```

### **Issue 3: "Invalid mime type"**
**Cause:** Upload file yang bukan image

**Solution:**
```dart
import 'package:mime/mime.dart';

final mimeType = lookupMimeType(file.path);
final allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];

if (mimeType == null || !allowedTypes.contains(mimeType)) {
  throw Exception('Only JPEG, PNG, and WebP images are allowed');
}
```

### **Issue 4: "Public URL returns 404"**
**Cause:** Bucket tidak public atau file tidak ada

**Solution:**
```sql
-- Set bucket to public
UPDATE storage.buckets 
SET public = true 
WHERE id = 'event_banners';
```

---

## 📦 Required Packages

```yaml
dependencies:
  supabase_flutter: ^2.10.2
  image_picker: ^1.0.4
  image: ^4.1.3  # For compression
  mime: ^1.0.4   # For MIME type checking
  path: ^1.8.3
```

---

## ✅ Setup Checklist

- [x] Create bucket `event_banners`
- [x] Set bucket to public
- [x] Configure MIME types (jpeg, png, webp, jpg)
- [x] Set max file size to 5MB
- [x] Create policy: Public Access Banner (SELECT)
- [x] Create policy: Organizer Upload Banner (INSERT)
- [x] Create policy: Organizer Manage Own Banner (UPDATE)
- [x] Create policy: Organizer Delete Own Banner (DELETE)
- [ ] Test upload dari app
- [ ] Test public URL access
- [ ] Test delete functionality
- [ ] Implement compression (optional but recommended)

---

## 📚 Resources

- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
- [RLS Policies Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Flutter Image Picker](https://pub.dev/packages/image_picker)
- [Image Compression in Flutter](https://pub.dev/packages/image)

---

**Storage Setup Complete! ✅**
Ready untuk implementasi di CreateEventScreen! 🚀
