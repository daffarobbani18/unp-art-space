import 'package:flutter/material.dart';
import '../../Features/home/screens/home_page.dart';
import '../../Features/search/screens/search_page.dart';
import '../../Features/upload/screens/upload_page.dart';
import '../../Features/notification/screens/notification_page.dart';
import '../../Features/core_navigation/screens/profile_page.dart';
import '../../shared/theme/app_theme.dart';

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
    HomePage(),
    SearchPage(),
    UploadPage(),
    NotificationPage(),
    ProfilePage(),
  ];

  // Fungsi yang akan dipanggil saat menu di-tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan menampilkan halaman yang aktif sesuai _selectedIndex
      body: _pages.elementAt(_selectedIndex), 

      // Bottom Navigation Bar dengan desain modern
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                ),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 1 ? Icons.search_rounded : Icons.search_outlined,
                ),
                label: 'Cari',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _selectedIndex == 2
                        ? LinearGradient(
                            colors: [AppTheme.secondary, AppTheme.secondaryLight],
                          )
                        : LinearGradient(
                            colors: [AppTheme.textTertiary, AppTheme.textTertiary],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: _selectedIndex == 2
                        ? [
                            BoxShadow(
                              color: AppTheme.secondary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                label: 'Upload',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 3 ? Icons.notifications_rounded : Icons.notifications_outlined,
                ),
                label: 'Notifikasi',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _selectedIndex == 4 ? Icons.person_rounded : Icons.person_outline_rounded,
                ),
                label: 'Profil',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppTheme.secondary,
            unselectedItemColor: AppTheme.textTertiary,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            elevation: 0,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}