import 'package:flutter/material.dart';
import '../../Features/home/screens/home_page_glass.dart';
import '../../Features/search/screens/search_page.dart';
import '../../Features/upload/screens/upload_page.dart';
import '../../Features/notifications/screens/notification_center_page.dart';
import '../../Features/core_navigation/screens/profile_page.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../../shared/widgets/mobile_only_dialog.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Variabel untuk melacak menu mana yang sedang aktif
  int _selectedIndex = 0; 

  // Daftar semua halaman utama kita
  static const List<Widget> _pages = <Widget>[
    HomePageGlass(),
    SearchPage(),
    UploadPage(),
    NotificationCenterPage(),
    ProfilePage(),
  ];

  // Fungsi yang akan dipanggil saat menu di-tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Tampilkan dialog mobile-only untuk web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MobileOnlyDialog.showIfWeb(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Penting untuk membuat bottom nav mengambang
      body: Stack(
        children: [
          // Body akan menampilkan halaman yang aktif sesuai _selectedIndex
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // Custom Bottom Navigation Bar dengan animasi pop-up
          Positioned(
            left: -11,
            right: -11,
            bottom: -35,
            child: SafeArea(
              child: CustomBottomNavBar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onItemTapped,
              ),
            ),
          ),
        ],
      ),
    );
  }
}