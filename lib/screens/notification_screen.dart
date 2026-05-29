import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_post_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Semua Notifikasi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      // Membaca SEMUA postingan dari database secara real-time, diurutkan dari yang paling baru
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .limit(50) // Batasi 50 notifikasi terbaru agar aplikasi tidak berat
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1E2F3E)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada aktivitas lalu lintas.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          var notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var data = notifications[index].data() as Map<String, dynamic>;
              String postId = notifications[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                elevation: 0, // Desain flat ala iOS/Modern UI
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1E2F3E),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  ),
                  title: Text(
                    "🚨 Macet: ${data['location'] ?? 'Lokasi...'}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "${data['username'] ?? 'Seseorang'} memposting laporan baru",
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  
                  // Kalau notifikasi diklik, langsung terbang ke Detail Laporan tersebut!
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPostScreen(
                          postId: postId,
                          name: data['name'] ?? 'Anonim',
                          username: data['username'] ?? 'anonim',
                          location: data['location'] ?? 'Lokasi...',
                          caption: data['caption'] ?? '',
                          imageBase64: data['image'] ?? '',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}