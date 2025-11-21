# CustomNetworkImage - Widget Optimasi Gambar

## 📦 Package Terinstall
```bash
flutter pub add cached_network_image
```

## 📋 Import
```dart
import 'package:unp_art_space_mobile/app/shared/widgets/custom_network_image.dart';
```

## 🎯 Penggunaan

### 1. Basic Usage
```dart
CustomNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
)
```

### 2. Dengan Ukuran Custom
```dart
CustomNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 150,
  fit: BoxFit.cover,
)
```

### 3. Border Radius Custom
```dart
CustomNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 100,
  height: 100,
  borderRadius: 50, // Circular
  fit: BoxFit.cover,
)
```

### 4. Mengganti Image.network Existing
**Sebelum:**
```dart
Image.network(
  artwork['image_url'],
  fit: BoxFit.cover,
  width: 200,
  height: 200,
)
```

**Sesudah:**
```dart
CustomNetworkImage(
  imageUrl: artwork['image_url'],
  fit: BoxFit.cover,
  width: 200,
  height: 200,
)
```

## ✨ Fitur

### 1. **Caching Otomatis**
- Gambar di-cache secara otomatis
- Loading lebih cepat untuk gambar yang sama
- Hemat bandwidth

### 2. **Placeholder Loading**
- Background hitam gelap (Colors.grey[900])
- CircularProgressIndicator putih transparan
- Ukuran menyesuaikan container

### 3. **Error Handling**
- Icon broken_image_rounded
- Text "Gagal" dengan styling rapi
- Background abu gelap

### 4. **Fade Animation**
- fadeInDuration: 300ms
- fadeOutDuration: 300ms
- Transisi smooth

### 5. **Rounded Corners**
- Default borderRadius: 12px
- Bisa di-customize sesuai kebutuhan
- Menggunakan ClipRRect

## 🔄 Migration Guide

### Contoh 1: Avatar Profile
**Sebelum:**
```dart
CircleAvatar(
  backgroundImage: NetworkImage(user['avatar_url']),
  radius: 40,
)
```

**Sesudah:**
```dart
CustomNetworkImage(
  imageUrl: user['avatar_url'],
  width: 80,
  height: 80,
  borderRadius: 40, // Circular
  fit: BoxFit.cover,
)
```

### Contoh 2: Artwork Thumbnail
**Sebelum:**
```dart
Image.network(
  artwork['thumbnail_url'],
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
)
```

**Sesudah:**
```dart
CustomNetworkImage(
  imageUrl: artwork['thumbnail_url'],
  fit: BoxFit.cover,
)
```

### Contoh 3: Event Banner
**Sebelum:**
```dart
Container(
  width: 320,
  height: 180,
  child: Image.network(
    event['banner_url'],
    fit: BoxFit.cover,
  ),
)
```

**Sesudah:**
```dart
CustomNetworkImage(
  imageUrl: event['banner_url'],
  width: 320,
  height: 180,
  fit: BoxFit.cover,
  borderRadius: 16,
)
```

## 📋 Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `imageUrl` | `String` | ✅ | - | URL gambar yang akan di-load |
| `width` | `double?` | ❌ | null | Lebar gambar |
| `height` | `double?` | ❌ | null | Tinggi gambar |
| `fit` | `BoxFit?` | ❌ | BoxFit.cover | Cara gambar mengisi container |
| `borderRadius` | `double` | ❌ | 12.0 | Radius sudut gambar |

## 🎨 Customization

### Mengubah Warna Placeholder
Edit file `custom_network_image.dart`:
```dart
color: Colors.grey[900], // Ganti dengan warna lain
```

### Mengubah Ukuran Loading Indicator
```dart
CircularProgressIndicator(
  strokeWidth: 2, // Ganti nilai ini
  ...
)
```

### Mengubah Icon Error
```dart
Icon(
  Icons.broken_image_rounded, // Ganti icon
  size: 40, // Ganti ukuran
  ...
)
```

## 🚀 Performa Benefits

1. **Caching**: Gambar di-cache di storage lokal
2. **Memory Management**: Otomatis clear cache saat memory penuh
3. **Bandwidth**: Hemat bandwidth dengan cache
4. **UX**: Loading lebih smooth dengan fade animation
5. **Error Resilient**: Tidak crash saat gambar error

## 💡 Best Practices

1. **Selalu sediakan width/height** untuk performa lebih baik
2. **Gunakan BoxFit.cover** untuk gambar yang harus mengisi container
3. **Gunakan BoxFit.contain** untuk gambar yang harus tampil penuh
4. **Set borderRadius 0** jika tidak ingin rounded corners
5. **Wrap dengan AspectRatio** jika perlu maintain aspect ratio

## 📝 Contoh Lengkap dalam Widget

```dart
class ArtworkCard extends StatelessWidget {
  final Map<String, dynamic> artwork;

  const ArtworkCard({required this.artwork});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          CustomNetworkImage(
            imageUrl: artwork['image_url'] ?? '',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            borderRadius: 8,
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(artwork['title'] ?? ''),
          ),
        ],
      ),
    );
  }
}
```

## 🔧 Cache Management

### Clear Cache (Optional)
Jika perlu clear cache secara manual:
```dart
import 'package:cached_network_image/cached_network_image.dart';

// Clear semua cache
await CachedNetworkImage.evictFromCache(imageUrl);

// Clear cache by URL
await DefaultCacheManager().removeFile(imageUrl);
```

## ⚠️ Notes

- Package otomatis handle cache expiry
- Cache size limit default: 200 items
- Cache duration default: 7 hari
- Support semua format: JPG, PNG, GIF, WebP

## 📱 Compatibility

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Desktop (Windows, macOS, Linux)
