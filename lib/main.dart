import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  // 1. Wajib agar komunikasi ke native Android aman
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Jalankan sistem Notifikasi yang tadi sudah kita perbaiki
  NotificationService notificationService = NotificationService();
  await notificationService.initNotification();

  // 4. Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trafix',
      debugShowCheckedModeBanner: false,
      // Mengunci tema aplikasi ke mode gelap minimalis
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}
