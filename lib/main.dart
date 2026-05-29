import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'screens/main_dashboard.dart';
import 'screens/sign_in_screen.dart'; // Sesuaikan nama file Sign In
import 'screens/splash_screen.dart';  // Sesuaikan nama file Splash Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trafix',
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // ==========================================
      // TEMA TERANG (KUNCI DI HITAM & ABU-ABU)
      // ==========================================
      theme: ThemeData(
        useMaterial3: false, // <--- OBAT ANTI UNGU BAWAAN FLUTTER
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F4F4), 
          foregroundColor: Colors.black, 
          elevation: 0
        ),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.black, // Semua tombol, switch, loading jadi Hitam
          onPrimary: Colors.white, // Teks di atas tombol otomatis Putih
          secondary: Colors.black54,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      
      // ==========================================
      // TEMA GELAP (KUNCI DI PUTIH & ABU GELAP)
      // ==========================================
      darkTheme: ThemeData(
        useMaterial3: false, // <--- OBAT ANTI UNGU BAWAAN FLUTTER
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F), 
          foregroundColor: Colors.white, 
          elevation: 0
        ),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white, // Semua tombol, switch, loading jadi Putih
          onPrimary: Colors.black, // Teks di atas tombol otomatis Hitam
          secondary: Colors.white70,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      home: const SplashScreen(), 
    );
  }
}

// ====================================================================
// CLASS PENJAGA PINTU (AUTH WRAPPER)
// ====================================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              // Loading screen diatur menggunakan warna sesuai mode
              child: CircularProgressIndicator(), 
            ),
          );
        }
        if (snapshot.hasData) {
          return const MainDashboard();
        }
        return const SignInScreen(); 
      },
    );
  }
}