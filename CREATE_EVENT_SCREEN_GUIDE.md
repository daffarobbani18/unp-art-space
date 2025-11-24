# 📝 Create Event Screen - Documentation

## ✅ Implementasi Selesai!

Form pembuatan event telah berhasil dibuat dengan desain **Glassmorphism** yang konsisten dan integrasi lengkap dengan **Supabase Storage**.

---

## 🎨 UI Components

### **1. Header**
```dart
_buildHeader()
```
- **Back Button**: Glass button dengan icon arrow_back
- **Title**: "Buat Event Baru"
- **Subtitle**: "Isi form di bawah ini"

**Features:**
- Disabled saat loading
- Consistent glass design

---

### **2. Image Picker**
```dart
_buildImagePicker()
```

**States:**
- **Empty State**: 
  - Gradient circle icon
  - "Upload Banner Event" text
  - Format info: "JPEG, PNG, WebP (Max 5MB)"
  
- **With Image State**:
  - Preview image full cover
  - Dark gradient overlay
  - Edit button (purple circle, top-right)

**Functionality:**
```dart
Future<void> _pickImage()
```
- Menggunakan `ImagePicker`
- Max resolution: 1200x1200px
- Image quality: 85%
- File size validation: Max 5MB
- Error handling dengan SnackBar

**Image Picker Configuration:**
```dart
final XFile? image = await _picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 1200,
  maxHeight: 1200,
  imageQuality: 85,
);
```

---

### **3. Text Fields**
```dart
_buildTextField()
```

**Fields:**
1. **Judul Event**
   - Icon: title_rounded
   - Max lines: 1
   - Required field

2. **Deskripsi**
   - Icon: description_rounded
   - Max lines: 5 (multiline)
   - Required field

3. **Lokasi**
   - Icon: location_on_rounded
   - Max lines: 1
   - Required field

**Design:**
- Glass card dengan backdrop blur
- White text on dark background
- Purple-white border
- Validation error in red

**Validation:**
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Field wajib diisi';
  }
  return null;
}
```

---

### **4. Date & Time Picker**
```dart
_buildDateTimePicker()
```

**Two Buttons:**

**A. Date Picker**
- Shows selected date: "24 November 2025"
- Fallback: "Pilih Tanggal"
- Icon: calendar_today_rounded
- Format: `dd MMMM yyyy` (Indonesian)

**B. Time Picker**
- Shows selected time: "14:30"
- Fallback: "Pilih Waktu"
- Icon: access_time_rounded
- Format: HH:mm (24-hour)

**Visual States:**
- Unselected: White opacity 8%
- Selected: Purple opacity 15% + purple border

**Date Picker Dialog:**
```dart
final DateTime? picked = await showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime.now(),  // Can't pick past dates
  lastDate: DateTime.now().add(Duration(days: 365)),  // Max 1 year
  builder: (context, child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF8B5CF6),  // Purple theme
        ),
      ),
      child: child!,
    );
  },
);
```

**Time Picker Dialog:**
```dart
final TimeOfDay? picked = await showTimePicker(
  context: context,
  initialTime: TimeOfDay.now(),
  builder: (context, child) {
    // Same dark theme with purple accent
  },
);
```

---

### **5. Save Button**
```dart
_buildSaveButton()
```

**States:**
- **Normal**: Purple-blue gradient + shadow
- **Loading**: Grey gradient + CircularProgressIndicator

**Text:**
- Normal: "Simpan Event"
- Loading: "Menyimpan..."

**Functionality:**
```dart
Future<void> _saveEvent()
```

---

## 🔄 Save Event Flow

### **1. Validation**
```dart
if (!_formKey.currentState!.validate()) {
  return;  // Form has errors
}

if (_selectedDate == null || _selectedTime == null) {
  // Show warning SnackBar
  return;
}
```

### **2. Upload Banner**
```dart
Future<String?> _uploadBanner(File imageFile)
```

**Steps:**
1. Generate unique filename: `{timestamp}.jpg`
2. Create path: `event_banners/{filename}`
3. Upload to Supabase Storage:
   ```dart
   await Supabase.instance.client.storage
       .from('event_banners')
       .upload(path, imageFile);
   ```
4. Get public URL:
   ```dart
   final publicUrl = Supabase.instance.client.storage
       .from('event_banners')
       .getPublicUrl(path);
   ```
5. Return URL or null (on error)

**Error Handling:**
- StorageException with status codes
- Generic exceptions
- Returns null on failure

### **3. Combine Date & Time**
```dart
final eventDateTime = DateTime(
  _selectedDate!.year,
  _selectedDate!.month,
  _selectedDate!.day,
  _selectedTime!.hour,
  _selectedTime!.minute,
);
```

### **4. Insert to Database**
```dart
await Supabase.instance.client.from('events').insert({
  'title': _titleController.text.trim(),
  'content': _descriptionController.text.trim(),
  'location': _locationController.text.trim(),
  'event_date': eventDateTime.toIso8601String(),
  'image_url': imageUrl,  // null if no image
  'organizer_id': user.id,  // Current user ID
  'status': 'pending',  // Default status
});
```

**Data Structure:**
```typescript
{
  title: string,          // Required
  content: string,        // Required
  location: string,       // Required
  event_date: timestamp,  // Required (ISO 8601)
  image_url: string?,     // Optional (null if no banner)
  organizer_id: uuid,     // Auto from auth
  status: 'pending',      // Always pending for new events
  created_at: timestamp,  // Auto-generated
}
```

### **5. Success Flow**
```dart
// Show success message
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Event berhasil dibuat! 🎉'),
    backgroundColor: Colors.green,
    duration: Duration(seconds: 2),
  ),
);

// Navigate back to dashboard
Navigator.pop(context);
```

**Dashboard akan auto-refresh** karena menggunakan StreamBuilder!

---

## 🚨 Error Handling

### **1. Storage Errors**
```dart
on StorageException catch (e) {
  String message = 'Gagal upload banner';
  
  if (e.statusCode == '413') {
    message = 'Ukuran file terlalu besar (max 5MB)';
  } else if (e.statusCode == '415') {
    message = 'Format file tidak didukung';
  }
  
  // Show error SnackBar
}
```

**Status Codes:**
- `413`: Payload Too Large (file > 5MB)
- `415`: Unsupported Media Type (wrong MIME type)
- Other: Generic storage error

### **2. Auth Errors**
```dart
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  throw Exception('User tidak terautentikasi');
}
```

### **3. Generic Errors**
```dart
catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Terjadi kesalahan: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

### **4. Finally Block**
```dart
finally {
  if (mounted) {
    setState(() {
      _isLoading = false;  // Always reset loading state
    });
  }
}
```

---

## 🎨 Design Specifications

### **Color Palette:**
```dart
// Background Gradient
Color(0xFF0F2027) → Color(0xFF203A43) → Color(0xFF2C5364)

// Glass Card
backgroundColor: Colors.white.withOpacity(0.08)
borderColor: Colors.white.withOpacity(0.12)
blur: sigmaX: 10, sigmaY: 10

// Primary Purple
Color(0xFF8B5CF6)

// Secondary Blue
Color(0xFF3B82F6)

// Success
Colors.green

// Error
Colors.red[300]
```

### **Typography (Poppins):**
```dart
Header Title: 18px Bold
Header Subtitle: 12px Regular (60% opacity)
Field Label: 14px SemiBold (70% opacity)
Field Input: 15px Regular
Field Hint: 14px Regular (38% opacity)
Button Text: 16px Bold
```

### **Spacing:**
```dart
Padding Container: 20px
Card Padding: 16px
Field Gap: 16px
Section Gap: 24px
Button Padding Vertical: 16px
```

### **Border Radius:**
```dart
Glass Card: 20px
Text Field: 16px
Button: 16px
Date/Time Button: 16px
Back Button: 12px
```

---

## 📦 State Management

### **Controllers:**
```dart
final _titleController = TextEditingController();
final _descriptionController = TextEditingController();
final _locationController = TextEditingController();
```

### **State Variables:**
```dart
DateTime? _selectedDate;    // null = not selected
TimeOfDay? _selectedTime;   // null = not selected
File? _selectedImage;       // null = no image
bool _isLoading = false;    // false = idle, true = saving
```

### **Form Key:**
```dart
final _formKey = GlobalKey<FormState>();
```

### **Image Picker:**
```dart
final ImagePicker _picker = ImagePicker();
```

---

## 🧪 Testing Checklist

### **UI Testing:**
- [ ] Header tampil dengan back button
- [ ] Image picker empty state tampil
- [ ] Image picker selected state tampil dengan preview
- [ ] All text fields tampil dengan label & icon
- [ ] Date picker button tampil
- [ ] Time picker button tampil
- [ ] Save button tampil dengan gradient

### **Functionality Testing:**
- [ ] Back button navigate ke dashboard
- [ ] Image picker open gallery
- [ ] Image > 5MB ditolak dengan error message
- [ ] Date picker open calendar dialog
- [ ] Time picker open time dialog
- [ ] Form validation works (required fields)
- [ ] Submit tanpa date/time show warning
- [ ] Save button disabled saat loading
- [ ] Upload banner berhasil ke storage
- [ ] Public URL didapat setelah upload
- [ ] Insert ke database berhasil
- [ ] Success snackbar muncul
- [ ] Auto navigate back ke dashboard
- [ ] Dashboard auto-refresh menampilkan event baru

### **Error Handling Testing:**
- [ ] File > 5MB → Error "Ukuran file terlalu besar"
- [ ] Wrong format → Error "Format tidak didukung"
- [ ] No internet → Error message
- [ ] Empty form → Validation errors
- [ ] Upload failed → Error message
- [ ] Insert failed → Error message

---

## 🔗 Integration Points

### **1. From Dashboard (FAB):**
```dart
// organizer_main_screen.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CreateEventScreen(),
  ),
);
```

### **2. To Dashboard (After Save):**
```dart
// create_event_screen.dart
Navigator.pop(context);  // Simple pop
```

### **3. Supabase Storage:**
```dart
// Upload
Supabase.instance.client.storage
    .from('event_banners')
    .upload(path, file);

// Get URL
Supabase.instance.client.storage
    .from('event_banners')
    .getPublicUrl(path);
```

### **4. Supabase Database:**
```dart
// Insert
Supabase.instance.client
    .from('events')
    .insert(data);
```

---

## 🚀 Performance Optimizations

### **1. Image Optimization:**
```dart
maxWidth: 1200,      // Limit resolution
maxHeight: 1200,     // Limit resolution
imageQuality: 85,    // Compress to 85%
```

**Benefits:**
- Smaller file size
- Faster upload
- Less storage usage
- Better performance

### **2. File Size Check:**
```dart
final fileSize = await file.length();
if (fileSize > 5 * 1024 * 1024) {
  // Reject before upload
}
```

**Benefits:**
- Prevent unnecessary upload attempts
- Better UX with immediate feedback
- Save bandwidth

### **3. Mounted Check:**
```dart
if (mounted) {
  setState(() {
    // Update UI
  });
}
```

**Benefits:**
- Prevent memory leaks
- Avoid "setState after dispose" errors
- Safer async operations

---

## 📱 User Experience

### **Loading States:**
1. **Image Picker**: Instant feedback
2. **Date Picker**: Native dialog
3. **Time Picker**: Native dialog
4. **Save Button**: 
   - Disabled during loading
   - Show CircularProgressIndicator
   - Change text to "Menyimpan..."
   - Grey gradient

### **Success Feedback:**
- Green SnackBar dengan emoji 🎉
- Duration: 2 seconds
- Auto navigate back

### **Error Feedback:**
- Red/Orange SnackBar
- Clear error message
- Stay on screen (user can fix)

### **Validation Feedback:**
- Inline error messages
- Red text below field
- Clear indication

---

## 🔮 Future Enhancements

### **Planned Features:**
- [ ] Multiple image upload (gallery)
- [ ] Image cropping tool
- [ ] Draft save (auto-save form)
- [ ] Preview before submit
- [ ] Rich text editor for description
- [ ] Location picker (Google Maps)
- [ ] Event categories/tags
- [ ] Ticket pricing (paid events)
- [ ] Capacity limit setting
- [ ] Event duration (start & end time)

### **Technical Improvements:**
- [ ] Add image compression library
- [ ] Implement caching for uploaded images
- [ ] Add retry mechanism for failed uploads
- [ ] Implement offline support
- [ ] Add analytics tracking

---

## 📄 Files Modified

### **Created:**
1. ✅ `lib/organizer/create_event_screen.dart` (720 lines)
2. ✅ `SUPABASE_STORAGE_SETUP.md` (documentation)

### **Modified:**
1. ✅ `lib/organizer/organizer_main_screen.dart`
   - Added import: `create_event_screen.dart`
   - Updated FAB onTap: Navigate to CreateEventScreen

---

## ✅ Summary

Create Event Screen **Complete** dengan:
- ✅ Glassmorphism design consistent
- ✅ Image picker dengan validation
- ✅ Form dengan 3 text fields + validation
- ✅ Date & Time picker dengan dark theme
- ✅ Upload banner ke Supabase Storage
- ✅ Insert data ke events table
- ✅ Auto-set organizer_id dari auth
- ✅ Status default: 'pending'
- ✅ Comprehensive error handling
- ✅ Loading states
- ✅ Success feedback
- ✅ Auto navigate back
- ✅ Dashboard auto-refresh (StreamBuilder)
- ✅ No compilation errors

**Ready untuk testing dan production!** 🎉

---

## 🧪 Quick Test Guide

1. **Test Image Upload:**
   ```
   - Pilih gambar < 5MB → Success
   - Pilih gambar > 5MB → Error
   - Pilih video → Error (wrong format)
   ```

2. **Test Form Validation:**
   ```
   - Submit form kosong → Validation errors
   - Isi title only → Still errors
   - Isi semua field → No errors
   ```

3. **Test Date/Time:**
   ```
   - Pilih date di masa lalu → Disabled
   - Pilih date hari ini → OK
   - Pilih date di masa depan → OK
   - Submit tanpa date/time → Warning
   ```

4. **Test Save:**
   ```
   - Isi form lengkap + image → Success
   - Isi form lengkap tanpa image → Success (image_url = null)
   - Check dashboard → Event baru muncul
   - Check Supabase Storage → Banner tersimpan
   - Check database → Data lengkap
   ```

**Happy Testing!** 🚀
