# 📊 Organizer Dashboard - Documentation

## ✅ Implementasi Selesai!

Dashboard Organizer telah berhasil dibuat dengan desain **Glassmorphism Dark Mode** yang konsisten dengan aplikasi.

---

## 🎨 Fitur UI Dashboard

### 1. **Header Section**
```dart
_buildHeader()
```
- **Avatar Icon**: Circular gradient avatar dengan shadow
- **Greeting**: "Halo, Organizer" + nama organizer
- **Logout Button**: Glass button dengan loading state

**Desain:**
- Glass morphism style dengan backdrop blur
- Purple-blue gradient untuk avatar
- Responsive layout dengan Row

---

### 2. **Event List dengan StreamBuilder**
```dart
_buildEventList()
```
**Realtime Stream dari Supabase:**
```dart
Supabase.instance.client
  .from('events')
  .stream(primaryKey: ['id'])
  .eq('organizer_id', _currentUserId!)
  .order('created_at', ascending: false)
```

**State Handling:**
- ✅ Loading state → CircularProgressIndicator
- ✅ Error state → Glass error card
- ✅ Empty state → Beautiful empty illustration
- ✅ Data state → Scrollable list of event cards
- ✅ Pull to refresh support

---

### 3. **Event Card Design**
```dart
_buildEventCard(Map<String, dynamic> event)
```

**Komponen Card:**
1. **Image Banner** (160px height)
   - Menampilkan `image_url` dari database
   - Fallback gradient jika tidak ada gambar
   - Status chip di pojok kanan atas

2. **Event Info Section**
   - Title (bold, 18px, max 2 lines)
   - Date with calendar icon (formatted dengan intl)
   - Location with location icon

3. **Status Chip** (top-right overlay)
   - 🟢 **Open/Approved**: Green
   - 🟠 **Pending**: Orange
   - 🔴 **Rejected**: Red
   - With icon + text + shadow

**Interaksi:**
- OnTap → Navigate to detail (saat ini snackbar placeholder)
- Glass card dengan border dan blur effect

---

### 4. **Empty State**
```dart
_buildEmptyState()
```

**Visual Elements:**
- Large circular gradient icon (event_busy)
- "Belum Ada Event" heading
- Helpful description text
- Arrow pointing to FAB

**Desain:**
- Centered dalam glass card
- Purple-blue gradient circle background
- White typography dengan opacity hierarchy

---

### 5. **Floating Action Button (FAB)**
```dart
_buildFAB()
```

**Spesifikasi:**
- Size: 65x65px
- Shape: Circle
- Gradient: Purple to Blue
- Icon: Plus (+) 32px
- Shadow: Purple glow dengan blur 20px

**Fungsi:**
- OnTap → Navigate to CreateEventScreen (placeholder)
- Smooth ink splash effect

---

## 📊 Data Flow

### Struktur Data Event:
```dart
Map<String, dynamic> event = {
  'id': uuid,
  'title': String,
  'content': String?,
  'image_url': String?,
  'status': String, // 'pending' | 'open' | 'approved' | 'rejected'
  'event_date': timestamp?,
  'location': String?,
  'organizer_id': uuid,
  'created_at': timestamp,
}
```

### Query Filter:
```sql
SELECT * FROM events 
WHERE organizer_id = '{current_user_id}'
ORDER BY created_at DESC
```

### Realtime Updates:
- Menggunakan Supabase Stream
- Auto-update saat ada perubahan di database
- Efisien dengan primary key optimization

---

## 🎨 Color Palette

### Background Gradient:
```dart
LinearGradient(
  colors: [
    Color(0xFF0F2027), // Deep Blue Dark
    Color(0xFF203A43), // Medium Blue
    Color(0xFF2C5364), // Light Blue
  ],
)
```

### Accent Colors:
- **Primary Purple**: `Color(0xFF8B5CF6)`
- **Secondary Blue**: `Color(0xFF3B82F6)`
- **Success Green**: `Colors.green`
- **Warning Orange**: `Colors.orange`
- **Error Red**: `Colors.red`

### Glass Effect:
- Background: `Colors.white.withOpacity(0.08)`
- Border: `Colors.white.withOpacity(0.12)`
- Blur: `sigmaX: 10, sigmaY: 10`

---

## 📱 Layout Structure

```
OrganizerMainScreen
├── Scaffold
│   ├── body: Container (Gradient Background)
│   │   └── SafeArea
│   │       └── Column
│   │           ├── _buildHeader()
│   │           │   ├── Avatar (gradient circle)
│   │           │   ├── Greeting (name + role)
│   │           │   └── Logout Button
│   │           │
│   │           └── Expanded: _buildEventList()
│   │               └── StreamBuilder<List<Event>>
│   │                   ├── Loading State
│   │                   ├── Error State
│   │                   ├── Empty State
│   │                   └── ListView.builder
│   │                       └── _buildEventCard()
│   │                           ├── Image Banner
│   │                           ├── Status Chip
│   │                           └── Event Info
│   │
│   └── floatingActionButton: _buildFAB()
│       └── Gradient Circle + Icon
```

---

## 🔧 Functions

### State Management:
```dart
bool _isLoggingOut = false;
String _organizerName = 'Organizer';
String? _currentUserId;
```

### Lifecycle:
```dart
@override
void initState() {
  _loadOrganizerInfo(); // Load user data
}
```

### Data Loading:
```dart
Future<void> _loadOrganizerInfo()
// - Get current user ID
// - Fetch user name from 'users' table
// - Update state
```

### Logout:
```dart
Future<void> _handleLogout()
// - Show confirmation dialog
// - Sign out from Supabase
// - Navigate to AuthGate
// - Handle errors
```

### UI Builders:
- `_buildHeader()` → Header dengan avatar & greeting
- `_buildEventList()` → StreamBuilder untuk events
- `_buildEventCard()` → Individual event card
- `_buildEmptyState()` → Empty state illustration
- `_buildStatusChip()` → Status badge
- `_buildFAB()` → Floating action button
- `_buildGlassCard()` → Reusable glass container

---

## 🧪 Testing Checklist

### Visual Testing:
- [ ] Header tampil dengan nama organizer yang benar
- [ ] Logout button berfungsi dan menampilkan dialog
- [ ] Empty state tampil saat belum ada event
- [ ] Event cards tampil dengan layout yang benar
- [ ] Status chips warna sesuai dengan status
- [ ] FAB tampil di pojok kanan bawah
- [ ] Gradient background tampil smooth

### Functional Testing:
- [ ] StreamBuilder realtime update berfungsi
- [ ] Pull to refresh works
- [ ] Card onTap menampilkan snackbar
- [ ] FAB onTap menampilkan snackbar
- [ ] Logout flow lengkap (dialog → signout → navigate)
- [ ] Loading states tampil dengan benar
- [ ] Error handling works

### Data Testing:
- [ ] Query filter by organizer_id benar
- [ ] Date formatting dengan intl works (dd MMM yyyy, HH:mm)
- [ ] Status mapping (pending/open/rejected) benar
- [ ] Image placeholder muncul jika image_url null
- [ ] Location fallback to "Location TBA"

---

## 📦 Dependencies

### Required Packages:
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.10.2
  google_fonts: ^6.3.2
  intl: ^0.20.2  # For date formatting
```

### Imports:
```dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../app/core/navigation/auth_gate.dart';
```

---

## 🚀 Next Steps (TODO)

### 1. CreateEventScreen
```dart
// TODO: Implement halaman create event
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CreateEventScreen(),
  ),
);
```

**Fitur yang dibutuhkan:**
- Form title, content, date, location
- Image picker untuk banner
- Submit ke tabel events
- Validation

### 2. Event Detail Screen
```dart
// TODO: Implement halaman detail event
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EventDetailScreen(eventId: event['id']),
  ),
);
```

**Fitur yang dibutuhkan:**
- Tampil detail lengkap event
- Edit event
- Delete event
- View submissions
- Review artwork submissions

### 3. Enhanced Features:
- [ ] Search & filter events
- [ ] Event statistics (total submissions, approved, rejected)
- [ ] Notifications untuk submission baru
- [ ] Export event report
- [ ] Share event link

---

## 🎯 Performance Optimizations

### Implemented:
- ✅ StreamBuilder untuk realtime updates
- ✅ ListView.builder untuk lazy loading
- ✅ Conditional rendering (null checks)
- ✅ Image caching dengan NetworkImage
- ✅ RefreshIndicator untuk manual refresh

### Dapat Ditingkatkan:
- Implement pagination (limit 20 per page)
- Add image compression
- Cache user data di SharedPreferences
- Implement search debouncing
- Add skeleton loading

---

## 🐛 Known Issues & Solutions

### Issue 1: Date Format Locale
**Problem:** `DateFormat('dd MMM yyyy', 'id_ID')` requires locale initialization

**Solution:**
```dart
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await initializeDateFormatting('id_ID', null);
  runApp(MyApp());
}
```

### Issue 2: Stream Performance
**Problem:** Stream dapat membebani jika banyak events

**Solution:** Add pagination di query:
```dart
.range(start, end)
.limit(20)
```

### Issue 3: Image Loading
**Problem:** NetworkImage dapat lambat di koneksi buruk

**Solution:** Add CachedNetworkImage:
```yaml
cached_network_image: ^3.3.0
```

---

## 📸 Screenshots Guide

### Empty State:
- Avatar + Greeting header
- Glass card dengan icon event_busy
- "Belum Ada Event" text
- Arrow pointing to FAB

### With Events:
- List of event cards
- Each card shows banner, title, date, location, status
- Purple gradient FAB bottom-right
- Smooth scroll

### Loading State:
- Header visible
- Purple CircularProgressIndicator centered

### Error State:
- Header visible
- Red error icon in glass card
- Error message displayed

---

## 🎉 Summary

Dashboard Organizer **selesai** dengan fitur:
- ✅ Glassmorphism Dark Mode design
- ✅ Realtime event list dengan StreamBuilder
- ✅ Beautiful empty state
- ✅ Status-based color coding
- ✅ Pull to refresh
- ✅ Floating Action Button
- ✅ Proper error handling
- ✅ Loading states
- ✅ Responsive layout

**Ready untuk development CreateEventScreen berikutnya!** 🚀
