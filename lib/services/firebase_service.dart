import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Inisialisasi instance Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Fungsi untuk Mengirim Laporan Baru
  Future<void> addReport({
    required String uidPengirim,
    required String title,
    required String description,
    required String base64Image,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _db.collection('reports').add({
        'uid_pengirim': uidPengirim,
        'title': title,
        'description': description,
        'image_base64': base64Image,
        'location': GeoPoint(latitude, longitude),
        'status_jalan': 'Masih Macet',
        'timestamp': FieldValue.serverTimestamp(), // Catat waktu server otomatis
      });
      print("Laporan berhasil dikirim ke Firestore!");
    } catch (e) {
      print("Gagal mengirim laporan: $e");
    }
  }

  // 2. Fungsi untuk Mengambil Data Laporan (Untuk Home Screen)
  Stream<QuerySnapshot> getReports() {
    // Mengambil data dan mengurutkannya dari yang paling baru
    return _db.collection('reports')
              .orderBy('timestamp', descending: true)
              .snapshots();
  }
}