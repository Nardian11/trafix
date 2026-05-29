import 'package:flutter/material.dart';
import '../main.dart'; // Wajib di-import agar bisa memanggil AuthWrapper()

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Jeda selama 3 detik sebelum pindah
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Mengarahkan ke PENJAGA PINTU (AuthWrapper), bukan langsung ke SignIn
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor DIHAPUS agar bisa mengikuti mode gelap/terang dari main.dart
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Trafix',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
                // Warna dinamis mengikuti tema
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 60),
            Image.asset(
              'assets/logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 60),
            Text(
              'Real traffic, real time.',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                // Warna dinamis mengikuti tema dengan sedikit transparansi agar lebih elegan
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
