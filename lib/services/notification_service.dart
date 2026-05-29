import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Inisialisasi Sistem Notifikasi
  Future<void> initNotification() async {
    // 1. Meminta izin memunculkan notifikasi di HP
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. Setup ikon notifikasi bawaan Android (KUNCI PERBAIKAN: Gunakan @mipmap/ic_launcher)
    final initializationSettingsAndroid = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
    );

    // 3. Handle notifikasi ketika aplikasi sedang terbuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher', // <--- KUNCI PERBAIKAN
            ),
          ),
        );
      }
    });
  }

  // ========================================================
  // 4. FUNGSI BARU: Untuk memunculkan Pop-Up Manual / Testing
  // ========================================================
  Future<void> showPopUpNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'manual_pop_up_channel',
      'Trafix Live Updates',
      channelDescription: 'Notifikasi pop-up kemacetan manual',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher', // <--- KUNCI PERBAIKAN
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      id: 0,
      title: 'Hi Hasan!',
      body: 'Jalan Jendral Sudirman, No. 19 sudah lancar',
      notificationDetails: notificationDetails,
    );
  }

  // Mengambil Token Unik Perangkat (FCM Token) untuk dikirim ke Vercel nanti
  Future<String?> getDeviceToken() async {
    return await _fcm.getToken();
  }
}