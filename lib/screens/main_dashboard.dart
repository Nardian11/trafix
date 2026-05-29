import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0; // Index awal (Home)

  // Daftar layar yang akan ditampilkan sesuai urutan menu bawah
  final List<Widget> _screens = [
    const HomeScreen(),
    const DiscoverScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack digunakan agar state layar tidak hilang (scroll tidak reset) saat pindah tab
      body: IndexedStack(index: _selectedIndex, children: _screens),

      // SATU-SATUNYA BOTTOM NAVBAR DI APLIKASI
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // Background dinamis mengikuti latar belakang utama aplikasi (Terang/Gelap)
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Warna ikon aktif dinamis (Primary color)
        selectedItemColor: Theme.of(context).colorScheme.primary, 
        // Warna ikon pasif dinamis (Otomatis sedikit transparan agar elegan)
        unselectedItemColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4), 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28),
            activeIcon: Icon(Icons.home, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 28),
            activeIcon: Icon(Icons.search, size: 28),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border, size: 28),
            activeIcon: Icon(Icons.favorite, size: 28),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            activeIcon: Icon(Icons.person, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}