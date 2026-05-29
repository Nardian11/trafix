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
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Postingan Favorit',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
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
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada postingan favorit.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            );
          }

          var allPosts = snapshot.data!.docs;

          // LOGIKA FILTER: MURNI HANYA POSTINGAN YANG DI-LIKE OLEH USER
          var favoriteFeed = allPosts.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            List<dynamic> likedVoters = data['likedVoters'] ?? [];
            return likedVoters.contains(currentUid);
          }).toList();

          if (favoriteFeed.isEmpty) {
            return Center(
              child: Text(
                'Kamu belum menyukai laporan apapun.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
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
              String postUid = postData['uid'] ?? '';
              List<dynamic> likedVoters = postData['likedVoters'] ?? [];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(postUid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  String authorName = postData['name'] ?? 'Anonim';
                  String authorProfilePic = '';

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    var authorData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    authorName = authorData['username'] ?? authorName;
                    authorProfilePic = authorData['profilePic'] ?? '';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            backgroundImage: authorProfilePic.isNotEmpty
                                ? MemoryImage(base64Decode(authorProfilePic))
                                      as ImageProvider
                                : const NetworkImage(
                                    'https://i.pravatar.cc/150?img=11',
                                  ),
                          ),
                          title: Text(
                            postData['location'] ?? 'Nama Jalan',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "$authorName: ${postData['caption']}",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                            ),
                          ),

                          // ==========================================================
                          // KUNCI JAWABAN: TOMBOL UNFAVORITE INTERAKTIF
                          // ==========================================================
                          trailing: IconButton(
                            icon: Icon(
                              likedVoters.contains(currentUid)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: likedVoters.contains(currentUid)
                                  ? Colors.red
                                  : Theme.of(context).iconTheme.color,
                            ),
                            onPressed: () async {
                              if (currentUid == null) return;

                              // Logika Toggle: Jika sudah dilike, maka cabut (Unlike)
                              if (likedVoters.contains(currentUid)) {
                                await FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(postId)
                                    .update({
                                      'likedVoters': FieldValue.arrayRemove([
                                        currentUid,
                                      ]),
                                    });
                              } else {
                                // Jaga-jaga jika ingin melike kembali dari layar ini (meski jarang terjadi karena hilang dari list)
                                await FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(postId)
                                    .update({
                                      'likedVoters': FieldValue.arrayUnion([
                                        currentUid,
                                      ]),
                                    });
                              }
                            },
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
                                    name: authorName,
                                    username: authorName,
                                    location:
                                        postData['location'] ?? 'Lokasi...',
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
          );
        },
      ),
    );
  }
}
