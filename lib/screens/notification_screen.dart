import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_post_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor DIHAPUS agar otomatis ikut tema
      appBar: AppBar(
        // backgroundColor DIHAPUS
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // color DIHAPUS, otomatis menyesuaikan foregroundColor AppBar
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Semua Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold), // color DIHAPUS
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
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary, // Warna loading dinamis
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada aktivitas lalu lintas.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), // Warna teks kosong dinamis
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary, // Warna bulat ikon dinamis
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
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
                      style: TextStyle(
                        fontSize: 12, 
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8), // Warna dinamis elegan
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right, 
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.4), // Panah kanan otomatis berubah warna
                  ),
                  
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