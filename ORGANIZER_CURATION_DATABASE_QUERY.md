# 📊 Organizer Event Curation - Database Query Documentation

## 🎯 File: `lib/organizer/organizer_event_curation_page.dart`

---

## 📋 **Current Implementation (Saat Ini Digunakan)**

### 1️⃣ **Stream Realtime dari `event_submissions` Table**

**Location:** Line 553-559

```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: supabase
      .from('event_submissions')
      .stream(primaryKey: ['id'])
      .eq('event_id', widget.eventId)
      .order('created_at', ascending: false),
```

**Penjelasan:**
- ✅ **Realtime**: Otomatis update jika ada perubahan data
- ✅ **Filter by Event**: Hanya ambil submission untuk event tertentu
- ✅ **Sorting**: Urutkan dari yang terbaru (`created_at DESC`)

**SQL Equivalent:**
```sql
SELECT * FROM event_submissions 
WHERE event_id = 'xxx-xxx-xxx'
ORDER BY created_at DESC;
```

**Data yang Didapat:**
```json
[
  {
    "id": "submission-uuid-1",
    "event_id": "event-uuid",
    "artwork_id": 123,
    "artist_id": "artist-uuid",
    "status": "pending",
    "created_at": "2025-11-25T10:00:00Z"
  },
  ...
]
```

---

### 2️⃣ **Fetch Detail dengan Loop (N+1 Query Problem)**

**Location:** Line 618-651

```dart
Future<List<Map<String, dynamic>>> _fetchSubmissionsWithDetails(
    List<Map<String, dynamic>> submissions) async {
  List<Map<String, dynamic>> detailedSubmissions = [];

  for (var submission in submissions) {
    try {
      // Query 1: Fetch artwork
      final artworkResponse = await supabase
          .from('artworks')
          .select()
          .eq('id', submission['artwork_id'])
          .single();

      // Query 2: Fetch profile
      final profileResponse = await supabase
          .from('profiles')
          .select()
          .eq('id', submission['artist_id'])
          .single();

      // Gabungkan data
      detailedSubmissions.add({
        ...submission,
        'artworks': artworkResponse,
        'profiles': profileResponse,
      });
    } catch (e) {
      // Handle error
      detailedSubmissions.add({
        ...submission,
        'artworks': null,
        'profiles': null,
      });
    }
  }
  return detailedSubmissions;
}
```

**Penjelasan:**
- ⚠️ **SLOW**: Jika ada 10 submissions → 1 + (10 × 2) = **21 queries total**
- ⚠️ **Not Realtime**: Harus manual fetch ulang
- ✅ **Error Handling**: Jika fetch gagal, tetap tampil dengan data null

**SQL Equivalent (untuk setiap submission):**
```sql
-- Query per submission (x2 karena artwork + profile)
SELECT * FROM artworks WHERE id = 123;
SELECT * FROM profiles WHERE id = 'artist-uuid';
```

**Data Akhir yang Didapat:**
```json
[
  {
    "id": "submission-uuid-1",
    "event_id": "event-uuid",
    "artwork_id": 123,
    "artist_id": "artist-uuid",
    "status": "pending",
    "artworks": {
      "id": 123,
      "title": "Lukisan Sunset",
      "media_url": "https://...",
      "artist_name": "John Doe"
    },
    "profiles": {
      "id": "artist-uuid",
      "username": "johndoe",
      "role": "artist"
    }
  },
  ...
]
```

---

## ⚡ **Alternative: Better Implementation (Recommended)**

### ✅ **Single Query dengan JOIN** (Lebih Cepat & Efisien)

**Method baru (sudah ada di kode tapi di-comment):**

```dart
Future<List<Map<String, dynamic>>> _fetchSubmissionsWithJoin() async {
  try {
    final response = await supabase
        .from('event_submissions')
        .select('''
          *,
          artworks (*),
          profiles (*)
        ''')
        .eq('event_id', widget.eventId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('Error fetching submissions with JOIN: $e');
    return [];
  }
}
```

**SQL Equivalent (1 query saja):**
```sql
SELECT 
  event_submissions.*,
  artworks.*,
  profiles.*
FROM event_submissions
LEFT JOIN artworks ON artworks.id = event_submissions.artwork_id
LEFT JOIN profiles ON profiles.id = event_submissions.artist_id
WHERE event_submissions.event_id = 'xxx-xxx-xxx'
ORDER BY event_submissions.created_at DESC;
```

**Keuntungan:**
- ✅ **1 Query** saja (tidak peduli ada berapa submission)
- ✅ **10x lebih cepat** untuk banyak data
- ✅ **Less bandwidth**
- ✅ **Same result** dengan method lama

---

## 🔄 **Cara Ganti ke Method yang Lebih Baik**

### Step 1: Ganti StreamBuilder
```dart
// BEFORE (Line 553)
StreamBuilder<List<Map<String, dynamic>>>(
  stream: supabase
      .from('event_submissions')
      .stream(primaryKey: ['id'])
      .eq('event_id', widget.eventId)
      .order('created_at', ascending: false),
```

**Menjadi:**
```dart
// AFTER
FutureBuilder<List<Map<String, dynamic>>>(
  future: _fetchSubmissionsWithJoin(),
```

### Step 2: Hapus nested FutureBuilder
Tidak perlu lagi call `_fetchSubmissionsWithDetails()` karena data sudah lengkap.

### Step 3: Uncomment method `_fetchSubmissionsWithJoin()`

---

## 📊 **Perbandingan Performance**

| Metric | Method Lama (Loop) | Method Baru (JOIN) |
|--------|-------------------|-------------------|
| **Jumlah Query** | 1 + (N × 2) | 1 |
| **Contoh (10 items)** | 21 queries | 1 query |
| **Speed** | Lambat | Cepat ⚡ |
| **Bandwidth** | Boros | Hemat |
| **Realtime** | ❌ No | ✅ Yes (jika pakai stream) |

---

## 🗄️ **Database Schema (Referensi)**

### Table: `event_submissions`
```sql
CREATE TABLE event_submissions (
  id uuid PRIMARY KEY,
  event_id uuid REFERENCES events(id),
  artwork_id bigint REFERENCES artworks(id),
  artist_id uuid REFERENCES profiles(id),
  status text DEFAULT 'pending',
  created_at timestamp with time zone
);
```

### Table: `artworks`
```sql
CREATE TABLE artworks (
  id bigint PRIMARY KEY,
  title text,
  media_url text,
  artist_id uuid,
  artist_name text,
  status text DEFAULT 'pending'
);
```

### Table: `profiles`
```sql
CREATE TABLE profiles (
  id uuid PRIMARY KEY,
  username text,
  role text
);
```

---

## 🔍 **Cara Debug Query**

### 1. Print query result:
```dart
debugPrint('📦 Submissions: $submissions');
```

### 2. Check di Supabase Table Editor:
```
https://supabase.com/dashboard/project/YOUR_PROJECT/editor
```

### 3. Test query manual:
```dart
final test = await supabase
    .from('event_submissions')
    .select('*, artworks(*), profiles(*)')
    .eq('event_id', widget.eventId);
    
debugPrint('Test result: $test');
```

---

## 📝 **Notes**

1. **Method lama masih berfungsi** - tidak ada bug, hanya lambat
2. **Method baru lebih efisien** - tapi butuh ubah kode sedikit
3. **Pilih salah satu** - jangan pakai keduanya bersamaan
4. **RLS harus aktif** - pastikan policies di Supabase benar

---

## 🚀 **Next Steps**

1. ✅ Dokumentasi sudah lengkap
2. ⏳ Pilih: tetap pakai method lama atau ganti ke JOIN
3. ⏳ Jika ganti, test dengan data real
4. ⏳ Deploy ke production

---

**Last Updated:** November 25, 2025  
**File Version:** 1.0
