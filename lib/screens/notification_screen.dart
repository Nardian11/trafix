import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4), // Latar konsisten dengan Trafix
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // Kembali ke Home
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Contoh notifikasi jalan sudah lancar (Sesuai pop-up gambarmu)
          _buildNotificationCard(
            title: 'Hi Hasan!',
            message: 'Jalan Jendral Sudirman, No. 19 sudah lancar',
            time: 'Just now',
            isResolved: true, // true = ikon centang hijau
          ),
          const SizedBox(height: 12),
          
          // Contoh notifikasi peringatan kemacetan
          _buildNotificationCard(
            title: 'Peringatan Macet',
            message: 'Terjadi penumpukan kendaraan di Jl. Kapten Marinir.',
            time: '15 mins ago',
            isResolved: false, // false = ikon peringatan merah
          ),
          const SizedBox(height: 12),
          
          _buildNotificationCard(
            title: 'Hi Hasan!',
            message: 'Jalan Lintas Sumatera sudah lancar kembali. Safe trip!',
            time: '2 hours ago',
            isResolved: true,
          ),
        ],
      ),
    );
  }

  // Komponen pembuat kartu list notifikasi
  Widget _buildNotificationCard({
    required String title,
    required String message,
    required String time,
    required bool isResolved,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12), // Border abu-abu sangat tipis
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon status (Centang Hijau atau Peringatan Merah)
          Icon(
            isResolved ? Icons.check_circle : Icons.warning_amber_rounded,
            color: isResolved ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 16),
          // Teks Notifikasi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: const TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}