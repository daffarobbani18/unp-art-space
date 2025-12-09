# 🚀 Deployment Guide - Campus Art Space v1.1.0

## 📋 Daftar Perubahan v1.1.0

### ✨ Fitur Baru
- **AI Art Detection**: Deteksi otomatis untuk artwork yang dibuat dengan AI
- **User Management Enhancement**: Responsive layout dan user detail screen
- **Event Moderation Improvements**: Layout lebih responsif untuk desktop
- **Edit Profile**: Fitur lengkap untuk edit profile dengan image upload

### 🐛 Bug Fixes
- Fix indentation errors di user management screen
- Fix image display di event detail
- Improve grid layout responsiveness

---

## 🌐 Deployment ke Web (Vercel/Azure)

### Langkah 1: Build Web
```bash
flutter clean
flutter build web --release
```

### Langkah 2: Copy Build Files ke web-deploy
```bash
# Hapus folder lama
Remove-Item -Recurse -Force web-deploy/build

# Copy build baru
Copy-Item -Recurse build/web web-deploy/build
```

### Langkah 3: Commit & Push
```bash
git add .
git commit -m "build: update web deployment v1.1.0 with AI detection and admin improvements"
git push origin main
```

**✅ Vercel akan otomatis deploy setelah push**

---

## 📱 Deployment ke Android

### Langkah 1: Build APK/AAB

#### Option A: APK (untuk testing/manual distribution)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Option B: AAB (untuk Google Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Langkah 2: Upload ke GitHub Releases

1. Buat Release baru di GitHub:
   ```
   https://github.com/daffarobbani18/unp-art-space-mobile/releases/new
   ```

2. Tag version: `v1.1.0`

3. Release title: `Campus Art Space v1.1.0 - AI Detection & Admin Improvements`

4. Description:
   ```markdown
   ## 🎉 What's New in v1.1.0

   ### ✨ New Features
   - 🤖 **AI Art Detection**: Automatically detect AI-generated artworks
   - 👥 **Enhanced User Management**: Responsive admin panel with detailed user view
   - 🎨 **Improved Event Moderation**: Better desktop layout
   - ✏️ **Complete Edit Profile**: Full-featured profile editing with image upload

   ### 🐛 Bug Fixes
   - Fixed layout issues in user management screen
   - Improved image display in event details
   - Enhanced grid responsiveness across all screens

   ### 📥 Download
   - **APK for Android**: [Download Here](link-to-apk)
   - **Web Version**: [https://your-vercel-url.vercel.app](https://your-vercel-url.vercel.app)

   ### 📋 System Requirements
   - Android 6.0 (API 23) or higher
   - 50MB free storage
   - Internet connection required
   ```

5. Upload file `app-release.apk`

6. Klik "Publish release"

### Langkah 3: Update README.md dengan link download baru

Update link di README.md:
```markdown
[![Download APK](https://img.shields.io/badge/Download-APK-blue.svg)](https://github.com/daffarobbani18/unp-art-space-mobile/releases/download/v1.1.0/app-release.apk)
```

---

## 🔄 Deployment ke Azure VM (Otomatis via GitHub Actions)

Azure VM akan otomatis deploy setelah push ke main branch jika GitHub Actions sudah dikonfigurasi.

Cek status di:
```
https://github.com/daffarobbani18/unp-art-space-mobile/actions
```

---

## 📊 Verifikasi Deployment

### Web (Vercel)
1. Buka: https://your-vercel-url.vercel.app
2. Login sebagai admin
3. Cek menu "Manajemen Pengguna" - harus responsive
4. Cek "Moderasi Karya" - harus ada badge AI detection

### Android APK
1. Download APK dari GitHub Releases
2. Install di device
3. Login dan test fitur AI detection
4. Test admin panel improvements

### Database (Supabase)
- ✅ Otomatis sync, tidak perlu action manual
- AI detection sudah terintegrasi dengan Supabase Functions

---

## 🎯 Checklist Deployment Lengkap

- [ ] Update version di pubspec.yaml (1.1.0+2)
- [ ] Build web (`flutter build web --release`)
- [ ] Copy build ke web-deploy folder
- [ ] Commit & push web build
- [ ] Build APK (`flutter build apk --release`)
- [ ] Create GitHub Release v1.1.0
- [ ] Upload APK ke GitHub Releases
- [ ] Update README.md dengan link download baru
- [ ] Test web deployment di Vercel
- [ ] Test APK download dan installation
- [ ] Announce update ke users

---

## 📝 Notes

- **Web deployment**: Otomatis via Vercel setiap push ke main
- **Mobile deployment**: Manual via GitHub Releases
- **Version naming**: Semantic versioning (MAJOR.MINOR.PATCH+BUILD)
- **Build time**: Web ~5-10 menit, APK ~3-5 menit

---

## 🆘 Troubleshooting

### Web build gagal
```bash
flutter clean
flutter pub get
flutter build web --release
```

### APK terlalu besar
```bash
flutter build apk --split-per-abi --release
```

### Vercel tidak auto-deploy
- Cek webhook di Vercel dashboard
- Push dengan commit baru
- Trigger manual di Vercel

---

## 📞 Support

Jika ada masalah deployment:
1. Cek GitHub Actions logs
2. Cek Vercel deployment logs
3. Contact: [your-email@example.com]
