# 🔄 Git Workflow: Development → Production

## 📋 Struktur Repository

```
unp-art-space-mobile (Development)
    ↓ push perubahan
unp-art-space (Production/Azure)
```

## 🎯 Remotes Configuration

Repo `unp-art-space-mobile` memiliki 2 remotes:

```bash
# Development repo
origin → https://github.com/daffarobbani18/unp-art-space-mobile.git

# Production repo (Azure deployment)
azure → https://github.com/daffarobbani18/unp-art-space.git
```

---

## 🚀 Workflow Sehari-hari

### 1. **Development di Repo Mobile** (Normal flow)

```bash
# Edit code, buat fitur baru, dll
git add .
git commit -m "feat: your feature"

# Push ke repo development
git push origin main
```

✅ **Aman untuk development, tidak mempengaruhi production**

---

### 2. **Push ke Production (Azure) - Saat Siap Deploy**

Ketika fitur sudah stable dan siap production:

```bash
# Step 1: Pastikan local sudah up-to-date
git pull origin main

# Step 2: Fetch latest dari production
git fetch azure

# Step 3: Cek perbedaan (opsional, untuk review)
git log azure/main..main --oneline

# Step 4: Push ke production
git push azure main

# Jika ada konflik atau reject, gunakan force push (HATI-HATI!)
# git push azure main --force
```

⚠️ **IMPORTANT**: 
- `git push azure main` akan trigger Azure Static Web Apps rebuild
- Pastikan tidak ada breaking changes
- Test di local dulu sebelum push ke azure

---

## 🛡️ Safety Checks Sebelum Push ke Azure

### Checklist:

- [ ] ✅ Build berhasil di local: `flutter build web --release`
- [ ] ✅ Test fitur utama di local web
- [ ] ✅ Commit message jelas dan deskriptif
- [ ] ✅ Tidak ada file sensitif (API keys di code)
- [ ] ✅ Database schema compatible (jika ada perubahan)
- [ ] ✅ Deep link masih berfungsi (`/artwork/`, `/submission/`)

---

## 🔧 Commands Penting

### Cek Status Remotes
```bash
git remote -v
```

### Cek Perbedaan dengan Production
```bash
# Lihat commits yang ada di local tapi belum di azure
git log azure/main..main --oneline

# Lihat commits yang ada di azure tapi belum di local
git log main..azure/main --oneline

# Lihat diff files
git diff azure/main..main --stat
```

### Sync dari Production ke Local (Jika ada perubahan di azure)
```bash
git fetch azure
git merge azure/main
# atau
git pull azure main
```

### Force Push (HATI-HATI!)
```bash
# Jika git push azure main ditolak karena history berbeda
git push azure main --force

# Lebih aman: force-with-lease (gagal jika ada perubahan baru di remote)
git push azure main --force-with-lease
```

---

## ⚠️ Troubleshooting

### Problem 1: Push Rejected (non-fast-forward)

**Error:**
```
! [rejected]        main -> main (non-fast-forward)
```

**Solusi:**
```bash
# Fetch dulu
git fetch azure

# Cek perbedaan
git log azure/main..main --oneline

# Jika yakin local lebih baru, force push
git push azure main --force
```

### Problem 2: Konflik saat Merge

**Error:**
```
CONFLICT (content): Merge conflict in ...
```

**Solusi:**
```bash
# Resolve conflicts di editor
# Setelah selesai:
git add .
git commit -m "fix: resolve merge conflicts"
git push azure main
```

### Problem 3: Azure Build Gagal

**Cek di:**
1. Azure Portal → Static Web Apps → Deployment History
2. GitHub Actions tab di repo `unp-art-space`

**Common issues:**
- Flutter version mismatch
- Missing dependencies
- Build folder tidak ada

**Fix:**
```bash
# Rebuild locally
flutter clean
flutter pub get
flutter build web --release

# Commit build artifacts jika perlu
git add build/web web-deploy
git commit -m "chore: rebuild web"
git push azure main
```

---

## 📊 Current Status

**Total commits ahead of production:** ~100+ commits

**Major changes not yet in production:**
- ✅ Platform-Aware Landing Page
- ✅ Admin Portal Redesign (Glass theme)
- ✅ Dashboard Analytics
- ✅ Event Management
- ✅ QR Code Integration
- ✅ Enhanced Artist Profiles
- ✅ Engagement Features (likes, comments, follows)
- ✅ Bug fixes & performance improvements

**Recommendation:**
- Test thoroughly in local/staging first
- Consider gradual rollout (push critical fixes first)
- Keep backup of production before big push

---

## 🎯 Recommended Flow

### For Daily Development:
```bash
# Work normally
git add .
git commit -m "your changes"
git push origin main
```

### For Production Deployment:
```bash
# Weekly or when stable
git push azure main
```

### Emergency Hotfix:
```bash
# Fix bug in production immediately
git add .
git commit -m "hotfix: critical bug"
git push azure main --force-with-lease
```

---

## 📝 Notes

1. **Jangan edit langsung di repo `unp-art-space`**
   - Semua development di `unp-art-space-mobile`
   - Production repo hanya menerima push dari mobile repo

2. **Azure Auto-Deploy**
   - Setiap push ke `azure` remote akan trigger GitHub Actions
   - Build & deploy otomatis ke Azure Static Web Apps
   - Monitor di GitHub Actions tab

3. **Config Files**
   - `vercel.json` → Tidak digunakan di Azure
   - `web-deploy/` → Optional, bisa dihapus jika tidak perlu
   - Build config ada di `.github/workflows/` (jika ada)

4. **Database**
   - Supabase URL sama di development & production
   - Hati-hati dengan perubahan schema
   - Test di development database dulu jika memungkinkan

---

## 🔗 Useful Links

- **Production**: https://[your-azure-domain].azurestaticapps.net
- **GitHub Development**: https://github.com/daffarobbani18/unp-art-space-mobile
- **GitHub Production**: https://github.com/daffarobbani18/unp-art-space
- **Supabase**: https://vepmvxiddwmpetxfdwjn.supabase.co

---

**Last Updated**: November 27, 2025  
**Setup Status**: ✅ Complete - Azure remote configured
