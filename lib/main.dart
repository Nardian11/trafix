import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';
import 'screens/sign_in_screen.dart';

// 1. Inisialisasi Plugin Notifikasi Lokal
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 2. Fungsi Penangan Notifikasi saat Aplikasi Terbunuh (Background)
// WAJIB diletakkan di luar class (top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Menangani pesan background: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set handler untuk background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Minta Izin Notifikasi (Terutama Android 13+)
  await requestNotificationPermission();

  // Konfigurasi Notifikasi Lokal agar bisa muncul pop-up saat aplikasi terbuka (Foreground)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Pengaturan khusus untuk iOS/macOS agar versi terbaru tidak error
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  // Inisialisasi dengan fungsi onDidReceiveNotificationResponse (WAJIB di versi terbaru)
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print("Pop-up notifikasi diklik! Payload: ${response.payload}");
    },
  );

  runApp(const MyApp());
}

// ========================================================
// FUNGSI-FUNGSI PENDUKUNG
// ========================================================

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Izin notifikasi diberikan!');
  } else {
    print('Izin notifikasi ditolak!');
  }
}

// Fungsi menampilkan pop-up notifikasi sederhana di Foreground
void showBasicNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'trafix_channel', // ID Channel
        'Notifikasi Trafix', // Nama Channel
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  // PERBAIKAN FINAL: Gunakan Named Parameters secara eksplisit
  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: title,
    body: body,
    notificationDetails: platformChannelSpecifics,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging();
  }

  void setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // OTOMATIS BERLANGGANAN KE TOPIK "kemacetan" (Sesuai tes Postman kita)
    await messaging.subscribeToTopic("kemacetan");
    print("Berhasil berlangganan ke topik: kemacetan");

    // Mendengarkan notifikasi saat aplikasi sedang TERBUKA (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Pesan diterima di Foreground!");
      if (message.notification != null) {
        showBasicNotification(
          message.notification!.title ?? "Trafix Update",
          message.notification!.body ?? "Ada info baru untukmu!",
        );
      }
    });

    // Mendengarkan jika notifikasi DIKLIK oleh user dari background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notifikasi diklik dari background!");
      // Tempat menambah navigasi jika diklik
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trafix',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SignInScreen(), // Mulai dari layar login
    );
  }
}
