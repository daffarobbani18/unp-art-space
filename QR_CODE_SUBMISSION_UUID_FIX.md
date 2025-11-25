# 🔧 Fix: QR Code dengan Submission UUID

## 📋 Masalah yang Diperbaiki

**BEFORE (Masalah):**
- QR Code menggunakan `artwork_id` (integer)
- Satu artwork bisa muncul di multiple events → duplikasi ID
- Tidak bisa membedakan submission mana yang di-scan

**AFTER (Solusi):**
- QR Code menggunakan `submission.id` (UUID)
- Setiap submission unik per event
- Tracking lebih akurat untuk analytics

---

## 🔄 Perubahan Code

### 1. **Organizer Event Curation Page**
**File:** `lib/organizer/organizer_event_curation_page.dart`

**Perubahan:**
```dart
// BEFORE
void _showQrDialog(BuildContext context, int artworkId, ...)
data: 'https://campus-art-space.vercel.app/artwork/$artworkId'

// AFTER
void _showQrDialog(BuildContext context, String submissionId, ...)
data: 'https://campus-art-space.vercel.app/submission/$submissionId'
```

**Button QR Code:**
```dart
// BEFORE
final artworkId = artwork?['id'] as int?;
if (artworkId != null) {
  _showQrDialog(context, artworkId, ...);
}

// AFTER
_showQrDialog(context, submissionId, ...); // langsung pakai submission ID
```

---

### 2. **Main App Routing**
**File:** `lib/main/main_app.dart`

**Tambah Route Baru:**
```dart
onGenerateRoute: (settings) {
  // Priority 1: /submission/{uuid} (QR Code)
  if (settings.name != null && settings.name!.startsWith('/submission/')) {
    final submissionId = settings.name!.replaceFirst('/submission/', '');
    return MaterialPageRoute(
      builder: (context) => ArtworkDetailPage.fromSubmission(
        submissionId: submissionId
      ),
    );
  }
  
  // Priority 2: /artwork/{id} (Legacy)
  if (settings.name != null && settings.name!.startsWith('/artwork/')) {
    final artworkId = int.tryParse(settings.name!.replaceFirst('/artwork/', ''));
    return MaterialPageRoute(
      builder: (context) => ArtworkDetailPage.fromId(artworkId: artworkId),
    );
  }
}
```

---

### 3. **Artwork Detail Page**
**File:** `lib/app/Features/artwork/screens/artwork_detail_page.dart`

**Tambah Constructor:**
```dart
class ArtworkDetailPage extends StatefulWidget {
  final Map<String, dynamic>? artwork;
  final int? artworkId;
  final String? submissionId; // NEW

  // Constructor untuk QR Code scanning
  const ArtworkDetailPage.fromSubmission({
    Key? key, 
    required this.submissionId
  }) : artwork = null, artworkId = null, super(key: key);
}
```

**Tambah Method Fetch:**
```dart
Future<void> _fetchArtworkFromSubmission() async {
  // Step 1: Get submission to find artwork_id
  final submissionResponse = await Supabase.instance.client
      .from('event_submissions')
      .select('id, artwork_id, artist_id, status')
      .eq('id', widget.submissionId!)
      .maybeSingle();

  final artworkId = submissionResponse['artwork_id'];
  
  // Step 2: Fetch artwork with user info
  final artworkResponse = await Supabase.instance.client
      .from('artworks')
      .select('*, users(*)')
      .eq('id', artworkId)
      .maybeSingle();
      
  setState(() {
    _loadedArtwork = artworkResponse;
  });
}
```

**Init State:**
```dart
void initState() {
  if (widget.submissionId != null) {
    _fetchArtworkFromSubmission(); // NEW: untuk QR code
  } else if (widget.artworkId != null) {
    _fetchArtworkData(); // Existing: untuk legacy
  } else {
    _loadedArtwork = widget.artwork; // Existing: dari navigation
  }
}
```

---

## 🗄️ Database & RLS

### **SQL Script yang Perlu Dijalankan:**

**File:** `supabase_rls_event_submissions_public.sql`

```sql
-- Allow anonymous users to SELECT event_submissions
CREATE POLICY "anon_select_event_submissions"
ON public.event_submissions
FOR SELECT
TO anon
USING (true);

-- Allow authenticated users to SELECT all submissions
CREATE POLICY "authenticated_select_event_submissions"
ON public.event_submissions
FOR SELECT
TO authenticated
USING (true);
```

**Kenapa Perlu:**
- Guest users (tidak login) bisa scan QR code
- Query ke `event_submissions` tidak akan di-block oleh RLS
- Artwork data sudah punya policy dari script sebelumnya

---

## 🧪 Testing Steps

### **1. Test di Mobile/Desktop App**

```bash
# Run app
flutter run -d chrome

# Atau
flutter run -d windows
```

**Test Flow:**
1. Login sebagai Organizer
2. Buka event → Kurasi karya
3. Approve karya
4. Klik "Lihat QR Code"
5. Screenshot QR code
6. Scan dengan app QR scanner
7. URL harus: `https://campus-art-space.vercel.app/submission/{uuid}`
8. Halaman harus redirect ke detail artwork

---

### **2. Test di Web (Vercel)**

**URL Format:**
```
https://campus-art-space.vercel.app/submission/550e8400-e29b-41d4-a716-446655440000
```

**Expected Result:**
- ✅ Page load detail artwork
- ✅ Tidak ada error "Karya tidak ditemukan"
- ✅ Guest mode banner muncul jika tidak login
- ✅ Like/comment buttons muncul jika sudah login

**Debug di Browser Console:**
```javascript
// Cek logs
🔍 Fetching artwork from submission UUID: {uuid}
📦 Submission Response: {...}
📌 Found artwork_id: 123
🎨 Artwork Response: {...}
✅ Artwork found from submission: {title}
```

---

### **3. Test RLS Policies**

**Di Supabase SQL Editor:**

```sql
-- Test 1: Anonymous user bisa query event_submissions
SET ROLE anon;
SELECT * FROM event_submissions WHERE id = 'your-submission-uuid';
-- Expected: Returns data

-- Test 2: Anonymous user bisa query artworks
SELECT * FROM artworks WHERE id = 123;
-- Expected: Returns data (if status = 'approved')

-- Reset role
RESET ROLE;
```

---

## 🔍 Troubleshooting

### **Problem: "Karya tidak ditemukan"**

**Possible Causes:**
1. ❌ RLS policy belum di-apply
2. ❌ Submission ID tidak valid
3. ❌ Artwork sudah dihapus

**Solution:**
```bash
# Check logs di browser console (F12)
# Atau di terminal jika run mobile app

# Expected logs:
🔍 Fetching artwork from submission UUID: xxx
📦 Submission Response: {...}
📌 Found artwork_id: 123
🎨 Artwork Response: {...}
✅ Artwork found from submission: ...
```

---

### **Problem: "Error: artworks not found"**

**Cause:** JOIN query mungkin gagal karena RLS

**Solution:**
Pakai 2-step query (sudah diperbaiki):
1. Query `event_submissions` untuk dapat `artwork_id`
2. Query `artworks` dengan `artwork_id` tersebut

---

### **Problem: QR code masih pakai /artwork/{id}**

**Cause:** Build belum di-deploy

**Solution:**
```bash
flutter build web --release
.\deploy.ps1
git add .
git commit -m "Update QR code system"
git push origin main
```

---

## 📊 Data Flow

```
┌─────────────────────────────────────────────────────┐
│ 1. Organizer approve artwork                        │
│    → event_submissions.status = 'approved'          │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ 2. Generate QR Code                                 │
│    → URL: /submission/{submission.id}               │
│    → submission.id = UUID (unique per event)        │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ 3. User scan QR code                                │
│    → Browser open: campus-art-space.vercel.app      │
│    → Route: /submission/{uuid}                      │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ 4. Flutter Web Routing                              │
│    → onGenerateRoute detects '/submission/'         │
│    → Navigate to ArtworkDetailPage.fromSubmission() │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ 5. Fetch Data (2 queries)                           │
│    → Query event_submissions → get artwork_id       │
│    → Query artworks → get full artwork data         │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│ 6. Display Artwork Detail                           │
│    → Show artwork info, image, description          │
│    → Show artist profile                            │
│    → Guest mode banner if not logged in             │
└─────────────────────────────────────────────────────┘
```

---

## ✅ Checklist Deploy

- [x] Update QR code generation code
- [x] Update routing in main_app.dart
- [x] Add ArtworkDetailPage.fromSubmission()
- [x] Add _fetchArtworkFromSubmission() method
- [x] Build Flutter web
- [x] Deploy to Vercel
- [ ] Run SQL script di Supabase (supabase_rls_event_submissions_public.sql)
- [ ] Test QR code scanning
- [ ] Verify guest mode works
- [ ] Verify logged in mode works

---

## 📝 Next Steps

1. **Run SQL Script:**
   - Buka Supabase Dashboard
   - SQL Editor → New query
   - Copy paste `supabase_rls_event_submissions_public.sql`
   - Run query

2. **Test QR Code:**
   - Generate QR dari organizer panel
   - Scan dengan phone/app
   - Pastikan redirect ke detail page

3. **Monitor Logs:**
   - Check Vercel deployment logs
   - Check browser console untuk error
   - Check Supabase logs untuk query issues

---

**Last Updated:** November 25, 2025  
**Status:** ✅ Code deployed, ⏳ SQL pending
