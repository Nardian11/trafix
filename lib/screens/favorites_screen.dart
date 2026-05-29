import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Favorites',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Silakan login untuk melihat favorit.'))
          : StreamBuilder<QuerySnapshot>(
              // Mengambil data jalan yang difavoritkan oleh user aktif
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('favorites')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1E2F3E)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada jalan yang difavoritkan.\nTekan ikon hati pada postingan di beranda!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                var favDocs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: favDocs.length,
                  itemBuilder: (context, index) {
                    var favData = favDocs[index].data() as Map<String, dynamic>;
                    String locationName = favData['location'] ?? 'Nama Jalan';
                    String postId = favDocs[index].id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildFavoriteCard(context, user.uid, postId, locationName),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, String uid, String postId, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12, width: 0.5), 
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Color(0xFF1E2F3E), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Memantau live update jalur ini', 
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          // Tombol Hapus Langsung dari Tab Favorites
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () async {
              // 1. Hapus dari database sub-koleksi favorites user
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('favorites')
                  .doc(postId)
                  .delete();

              // 2. Kurangi jumlah like di postingan aslinya
              await FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .update({
                'likesCount': FieldValue.increment(-1),
              });
            },
          ),
        ],
      ),
    );
  }
}