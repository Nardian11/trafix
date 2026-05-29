import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'screens/main_dashboard.dart';
import 'screens/sign_in_screen.dart'; // Sesuaikan nama file Sign In
import 'screens/splash_screen.dart';  // PASTIKAN IMPORT FILE SPLASH SCREEN KAMU DI SINI

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
      
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF4F4F4), foregroundColor: Colors.black, elevation: 0),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F1F1F), foregroundColor: Colors.white, elevation: 0),
        cardColor: const Color(0xFF1E1E1E),
      ),
      
      // KEMBALIKAN POSISI HOME KE SPLASH SCREEN
      home: const SplashScreen(), // Sesuaikan dengan nama class Splash Screen-mu
    );
  }
}

// ====================================================================
// CLASS BARU: PENJAGA PINTU (AUTH WRAPPER)
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
            body: Center(child: CircularProgressIndicator(color: Color(0xFF1E2F3E))),
          );
        }
        if (snapshot.hasData) {
          return const MainDashboard();
        }
        return const SignInScreen(); // Sesuaikan dengan class Sign In kamu
      },
    );
  }
}