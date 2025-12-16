# Testing Guest Mode Implementation

## ✅ Cara Test Guest Mode Setelah Deployment

### 1. **Clear Browser Cache (Hard Refresh)**
```
Chrome/Edge: Ctrl + Shift + R atau Ctrl + F5
Firefox: Ctrl + Shift + R
Safari: Cmd + Option + R
```

### 2. **Incognito/Private Mode**
- Buka browser dalam mode incognito
- Akses URL: `https://campus-art-space.vercel.app/submission/{uuid}`
- Pastikan tidak ada session/cookie tersimpan

### 3. **Clear Service Worker**
1. Buka DevTools (F12)
2. Go to **Application** tab
3. Click **Service Workers** di sidebar kiri
4. Click **Unregister** untuk setiap service worker
5. Refresh halaman (F5)

### 4. **Clear All Site Data**
1. Buka DevTools (F12)
2. Go to **Application** tab
3. Click **Clear storage** di sidebar kiri
4. Click **Clear site data** button
5. Refresh halaman (F5)

## 🧪 Skenario Testing

### **Scenario 1: QR Code Scan (Guest Mode)**

1. **Scan QR Code** dari artwork fisik
2. **Expected Behavior:**
   - ✅ Halaman detail artwork terbuka
   - ✅ Bisa melihat gambar, judul, deskripsi
   - ✅ Bottom action bar menampilkan **"Download Aplikasi"** banner (purple-blue gradient)
   - ✅ Banner text: "Untuk like, comment & interaksi lainnya"

3. **Ketika tap Like button:**
   - ❌ Tidak ada tombol like yang visible (diganti dengan banner)
   - Jika somehow tap like area → Dialog muncul:
     - Title: "Suka Karya Ini?"
     - Icon: ❤️ Favorite (red gradient)
     - Message: "Download aplikasi Campus Art Space untuk menyukai karya..."
     - Features list: 4 benefits
     - Button: "Download Aplikasi" (purple-blue gradient)
     - Button: "Nanti Saja" (text button)

4. **Ketika tap Comment button:**
   - ❌ Tidak ada tombol comment yang visible (diganti dengan banner)
   - Jika somehow tap comment area → Dialog muncul:
     - Title: "Ingin Berkomentar?"
     - Icon: 💬 Chat Bubble (blue gradient)
     - Message: "Download aplikasi Campus Art Space untuk berbagi pendapat..."
     - Features list: 4 benefits
     - Button: "Download Aplikasi" (purple-blue gradient)
     - Button: "Nanti Saja" (text button)

5. **Ketika tap "Download Aplikasi":**
   - Dialog kedua muncul dengan 2 opsi:
     - "Login untuk Berinteraksi" → Navigasi ke Login page
     - "Download Aplikasi" → Snackbar info bahwa app sedang dalam pengembangan

### **Scenario 2: Logged In User (Normal Mode)**

1. **Login** sebagai user (artist/visitor)
2. **Navigate** ke artwork detail page
3. **Expected Behavior:**
   - ✅ Bottom action bar menampilkan **Like & Comment buttons**
   - ✅ Like button berfungsi normal (toggle like/unlike)
   - ✅ Comment button berfungsi normal (buka comment modal)
   - ✅ Tidak ada banner "Download Aplikasi"

## 🔧 Debugging

### Check Guest Mode Status
Buka DevTools Console (F12) dan cek:
```javascript
// Check if user is logged in
console.log('Supabase User:', supabase.auth.currentUser);

// If null → Guest Mode
// If object → Logged In
```

### Check Network Requests
1. Buka DevTools (F12)
2. Go to **Network** tab
3. Refresh page
4. Filter: `supabase` atau `auth`
5. Check response untuk session info

### Check Local Storage
1. Buka DevTools (F12)
2. Go to **Application** tab
3. Expand **Local Storage** → Select domain
4. Look for keys starting with `supabase.auth.token`
5. If empty → Guest Mode
6. If has token → Logged In

## 📱 Test URLs

### Production (Vercel)
```
https://campus-art-space.vercel.app/submission/{submission-uuid}
```

### Testing dengan QR Code
1. Generate QR code untuk submission ID
2. Scan dengan phone camera
3. Harus membuka browser (bukan app)
4. Check apakah guest mode aktif

## ✅ Success Criteria

- [ ] Guest user tidak bisa tap Like button (button tidak muncul, replaced by banner)
- [ ] Guest user tidak bisa tap Comment button (button tidak muncul, replaced by banner)
- [ ] Guest user melihat banner "Download Aplikasi" di bottom action bar
- [ ] Dialog muncul dengan desain glassmorphism yang konsisten
- [ ] Dialog menampilkan 4 features dengan icon dan gradient
- [ ] Button "Download Aplikasi" navigasi ke dialog kedua
- [ ] Button "Nanti Saja" menutup dialog
- [ ] Logged-in user melihat Like & Comment buttons (bukan banner)
- [ ] Logged-in user bisa like/unlike artwork
- [ ] Logged-in user bisa membuka comment modal

## 🐛 Troubleshooting

### Problem: Banner tidak muncul
**Solution:**
- Clear browser cache dan refresh
- Check console untuk errors
- Verify `_isGuestMode` flag di code

### Problem: Dialog tidak muncul
**Solution:**
- Check imports: `dart:ui` untuk ImageFilter
- Check `_showGuestActionDialog()` function exists
- Verify dialog is called in `_toggleLike()` dan `_showCommentsModal()`

### Problem: Masih bisa like/comment sebagai guest
**Solution:**
- Verify conditional rendering: `_isGuestMode ? _buildGuestModeBanner() : Row([...])`
- Check initState() sets `_isGuestMode = user == null`
- Verify `_showCommentsModal()` has guest check at top

## 📞 Contact

Jika masih ada issue, cek:
1. Git commit hash: `fc65ae9` (latest)
2. Vercel deployment status
3. Browser console untuk errors
4. Network tab untuk API calls

---

**Last Updated:** December 16, 2025
**Version:** 1.0.0 - Guest Mode Implementation
