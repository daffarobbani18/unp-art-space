# CustomBottomNavBar - Widget Bottom Navigation Interaktif

## 📝 Deskripsi
CustomBottomNavBar adalah widget bottom navigation bar kustom dengan animasi pop-up yang elegan untuk item yang aktif. Widget ini menggunakan glassmorphism design dengan efek blur dan gradien yang menarik.

## ✨ Fitur Utama

### 1. **Desain Glassmorphism**
- Background gelap (#1E1E2C) dengan efek blur
- Border transparan putih
- Shadow untuk efek floating/mengambang
- Border radius tinggi (35px) untuk tampilan modern

### 2. **Animasi Pop-up Interaktif**
- **Item Tidak Aktif**: 
  - Icon ditampilkan dengan warna abu-abu (opacity 0.4)
  - Posisi normal di tengah bar
  - Label text muncul di bawah icon
  
- **Item Aktif**:
  - Icon bergerak naik 28px (keluar dari batas atas bar)
  - Background lingkaran gradien oranye-merah (#FF6B6B → #FF8E53)
  - Icon berubah warna putih solid
  - Label menghilang dengan fade effect
  - Scale animation (0.8 → 1.0) untuk efek "pop"
  - Shadow berwarna sesuai gradient

### 3. **5 Menu Utama**
1. **Home** - Icon: `home_rounded`
2. **Jelajahi** - Icon: `search_rounded`
3. **Upload** - Icon: `add_rounded` (ukuran lebih besar, center)
4. **Notifikasi** - Icon: `notifications_rounded`
5. **Profile** - Icon: `person_rounded`

### 4. **Smooth Transitions**
- Duration: 300ms untuk perpindahan posisi
- Duration: 200ms untuk opacity changes
- Curve: `Curves.easeInOut` untuk animasi natural

## 🎯 Cara Penggunaan

### 1. Import Widget
```dart
import 'package:unp_art_space_mobile/app/shared/widgets/custom_bottom_nav_bar.dart';
```

### 2. Implementasi di Scaffold dengan Stack
```dart
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // PENTING: untuk membuat bottom nav mengambang
      body: Stack(
        children: [
          // Konten halaman Anda
          IndexedStack(
            index: _selectedIndex,
            children: [
              HomePage(),
              SearchPage(),
              UploadPage(),
              NotificationPage(),
              ProfilePage(),
            ],
          ),
          
          // Custom Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Menggunakan MainNavigation (Contoh Lengkap)
File `main_navigation.dart` sudah menyediakan implementasi lengkap. Cukup navigasi ke widget ini:

```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const MainNavigation()),
);
```

## 🎨 Customization

### Mengubah Warna Gradient
Edit file `custom_bottom_nav_bar.dart`:
```dart
gradient: const LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFF6B6B), // Ganti warna 1
    Color(0xFFFF8E53), // Ganti warna 2
  ],
)
```

### Mengubah Warna Background
```dart
color: const Color(0xFF1E1E2C).withOpacity(0.9), // Ubah hex color
```

### Mengubah Tinggi Pop-up
```dart
transform: Matrix4.translationValues(
  0,
  isSelected ? -28 : 0, // Ubah nilai -28 untuk mengatur tinggi pop
  0,
)
```

### Mengubah Ukuran Icon
```dart
size: isCenter ? 32 : 26, // Ubah nilai untuk icon
```

## 📋 Properties

### CustomBottomNavBar
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `selectedIndex` | `int` | ✅ | Index item yang sedang aktif (0-4) |
| `onItemTapped` | `Function(int)` | ✅ | Callback ketika item di-tap |

## 🔧 Technical Details

### Animations Used
- `AnimationController` dengan `SingleTickerProviderStateMixin`
- `ScaleTransition` untuk efek scale saat item aktif
- `AnimatedContainer` untuk smooth positioning
- `AnimatedOpacity` untuk fade in/out label

### Dependencies
- `dart:ui` untuk `ImageFilter.blur`
- Standard Flutter material package

## 💡 Tips & Best Practices

1. **Selalu set `extendBody: true`** di Scaffold untuk membuat bottom nav mengambang
2. **Gunakan IndexedStack** untuk performance yang lebih baik dibanding PageView
3. **Pastikan background halaman tidak putih** agar efek glassmorphism terlihat
4. **Margin 20px** sudah optimal untuk tampilan mengambang
5. **Height 75px** sudah memperhitungkan pop-up effect, jangan kurangi

## 🐛 Troubleshooting

### Bottom Nav tidak mengambang
✅ **Solusi**: Pastikan `extendBody: true` di Scaffold

### Background tidak blur
✅ **Solusi**: Pastikan import `dart:ui` ada dan device support backdrop filter

### Animasi tersendat
✅ **Solusi**: Periksa apakah ada widget rebuild yang tidak perlu di parent

### Icon terpotong saat pop-up
✅ **Solusi**: Pastikan tidak ada `ClipRect` atau `overflow: hidden` di parent

## 📱 Compatibility
- ✅ iOS
- ✅ Android
- ✅ Web (dengan fallback untuk backdrop filter)
- ✅ Desktop

## 🎬 Demo Animation Flow
```
1. User tap item
2. AnimationController triggered (0.0 → 1.0)
3. Parallel animations:
   - Position: Y dari 0 → -28px (pop up)
   - Scale: 0.8 → 1.0 (scale effect)
   - Color: transparent → gradient
   - Label opacity: 1.0 → 0.0
4. Total duration: 300ms
5. Curve: easeInOut
```

## 📄 License
Part of UNP Art Space Mobile Application

## 👨‍💻 Author
Created for UNP Art Space Mobile App
