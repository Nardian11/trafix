import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_post_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      // backgroundColor DIHAPUS agar otomatis mengikuti Dark/Light Mode
      appBar: AppBar(
        // backgroundColor DIHAPUS
        elevation: 0,
        title: Text(
          'Jalan Pantauan Saya',
          style: TextStyle(
            // color: Colors.black DIHAPUS, ganti jadi dinamis
            color: Theme.of(context).textTheme.bodyLarge?.color, 
            fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary), // Warna dinamis
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada jalan pantauan favorit.',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)), // Dinamis
              ),
            );
          }

          var allPosts = snapshot.data!.docs;

          // STEP 1: Cari semua postingan yang pernah di-like oleh user ini
          var likedPosts = allPosts.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            List<dynamic> likedVoters = data['likedVoters'] ?? [];
            return likedVoters.contains(currentUid);
          }).toList();

          // STEP 2: Ekstrak kata kunci unik nama jalan dari postingan yang di-like
          Set<String> favoriteStreetKeywords = {};
          for (var doc in likedPosts) {
            var data = doc.data() as Map<String, dynamic>;
            String location = (data['location'] ?? '').toString().toLowerCase();

            // Memecah kalimat lokasi menjadi potongan kata (menghilangkan spasi dan komma)
            List<String> words = location.split(RegExp(r'[\s,.]+'));
            for (var word in words) {
              // Abaikan kata umum seperti "jalan", "jl", atau angka/kata pendek agar akurat
              if (word.length > 3 &&
                  word != 'jalan' &&
                  word != 'gang' &&
                  word != 'raya') {
                favoriteStreetKeywords.add(word);
              }
            }
          }

          // STEP 3: Filter timeline untuk menampilkan postingan serupa (unsur jalan sama)
          var favoriteFeed = allPosts.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String location = (data['location'] ?? '').toString().toLowerCase();
            List<dynamic> likedVoters = data['likedVoters'] ?? [];

            // Jika postingan ini memang di-like user, otomatis tampilkan
            if (likedVoters.contains(currentUid)) return true;

            // Jika lokasi postingan mengandung salah satu kata kunci jalan favorit user
            for (var keyword in favoriteStreetKeywords) {
              if (location.contains(keyword)) {
                return true;
              }
            }
            return false;
          }).toList();

          if (favoriteFeed.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada laporan macet terbaru di jalan favoritmu.',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)), // Dinamis
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: favoriteFeed.length,
            itemBuilder: (context, index) {
              var postData = favoriteFeed[index].data() as Map<String, dynamic>;
              String imgBase64 = postData['image'] ?? '';
              String postId = favoriteFeed[index].id;
              List<dynamic> likedVoters = postData['likedVoters'] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                // Card Color akan otomatis mengikuti theme.cardColor dari main.dart
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary, // Dinamis
                        child: const Icon(
                          Icons.add_road,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        postData['location'] ?? 'Nama Jalan',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Info: ${postData['caption']}",
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)), // Dinamis
                      ),
                      trailing: Icon(
                        likedVoters.contains(currentUid)
                            ? Icons.favorite
                            : Icons.star,
                        color: likedVoters.contains(currentUid)
                            ? Colors.red
                            : Colors.amber,
                      ),
                    ),
                    if (imgBase64.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPostScreen(
                                postId: postId,
                                name: postData['name'] ?? 'Anonim',
                                username: postData['username'] ?? 'anonim',
                                location: postData['location'] ?? 'Lokasi...',
                                caption: postData['caption'] ?? '',
                                imageBase64: imgBase64,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                          child: Image.memory(
                            base64Decode(imgBase64),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}