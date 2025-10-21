import 'package:flutter/material.dart';
import 'Features/core_navigation/screens/home_page.dart';
import 'Features/core_navigation/screens/jelajahi_page.dart';
import 'Features/core_navigation/screens/profile_page.dart';

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
    JelajahiPage(),
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

      // Di sinilah kita membuat Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Jelajahi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex, // Menu yang aktif saat ini
        selectedItemColor: Colors.deepPurple, // Warna menu aktif
        onTap: _onItemTapped, // Panggil fungsi saat di-tap
      ),
    );
  }
}