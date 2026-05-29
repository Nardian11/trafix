import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_post_screen.dart';
import 'notification_screen.dart';
import 'add_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.add_circle_outline,
            color: Colors.black,
            size: 28,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          ),
        ),
        title: const Text(
          'Trafix',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'serif',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E2F3E)),
            );
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text('Belum ada laporan.'));

          var posts = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var postData = posts[index].data() as Map<String, dynamic>;

              // Mengambil Array pemilih dari database
              List<dynamic> likedVoters = postData['likedVoters'] ?? [];
              List<dynamic> correctVoters = postData['correctVoters'] ?? [];
              List<dynamic> incorrectVoters = postData['incorrectVoters'] ?? [];
              int commentsCount = postData['commentsCount'] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: PostCardWidget(
                  postId: posts[index].id,
                  name: postData['name'] ?? 'Anonim',
                  username: postData['username'] ?? 'anonim',
                  location: postData['location'] ?? 'Lokasi...',
                  caption: postData['caption'] ?? '',
                  imageBase64: postData['image'] ?? '',
                  likedVoters: likedVoters,
                  correctVoters: correctVoters,
                  incorrectVoters: incorrectVoters,
                  commentsCount: commentsCount,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PostCardWidget extends StatelessWidget {
  final String postId, name, username, location, caption, imageBase64;
  final List<dynamic> likedVoters;
  final List<dynamic> correctVoters;
  final List<dynamic> incorrectVoters;
  final int commentsCount;

  const PostCardWidget({
    super.key,
    required this.postId,
    required this.name,
    required this.username,
    required this.location,
    required this.caption,
    required this.imageBase64,
    required this.likedVoters,
    required this.correctVoters,
    required this.incorrectVoters,
    required this.commentsCount,
  });

  @override
  Widget build(BuildContext context) {
    String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    bool hasLiked = likedVoters.contains(currentUid);
    bool hasVotedCorrect = correctVoters.contains(currentUid);
    bool hasVotedIncorrect = incorrectVoters.contains(currentUid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  location,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // PENCET GAMBAR UTK MASUK DETAIL
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPostScreen(
                  postId: postId,
                  name: name,
                  username: username,
                  location: location,
                  caption: caption,
                  imageBase64: imageBase64,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageBase64.isNotEmpty
                ? Image.memory(
                    base64Decode(imageBase64),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 200,
                    color: Colors.grey,
                    child: const Icon(Icons.image_not_supported),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // TOMBOL LIKE (SISTEM ARRAY)
            _buildAction(
              hasLiked ? Icons.favorite : Icons.favorite_border,
              hasLiked ? Colors.red : Colors.black87,
              likedVoters.length.toString(),
              () {
                if (currentUid == null) return;
                FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .update({
                      'likedVoters': hasLiked
                          ? FieldValue.arrayRemove([currentUid])
                          : FieldValue.arrayUnion([currentUid]),
                    });
              },
            ),
            const SizedBox(width: 16),

            // TOMBOL KOMENTAR (MENAMPILKAN JUMLAH NYATA)
            _buildAction(
              Icons.chat_bubble_outline,
              Colors.black87,
              '$commentsCount Balasan',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPostScreen(
                      postId: postId,
                      name: name,
                      username: username,
                      location: location,
                      caption: caption,
                      imageBase64: imageBase64,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),

            // TOMBOL SILANG (MUTUAL EXCLUSIVE)
            _buildAction(
              hasVotedIncorrect ? Icons.cancel : Icons.cancel_outlined,
              hasVotedIncorrect ? Colors.red : Colors.redAccent,
              incorrectVoters.length.toString(),
              () {
                if (currentUid == null) return;
                if (hasVotedIncorrect) {
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .update({
                        'incorrectVoters': FieldValue.arrayRemove([currentUid]),
                      });
                } else {
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .update({
                        'incorrectVoters': FieldValue.arrayUnion([currentUid]),
                        'correctVoters': FieldValue.arrayRemove([
                          currentUid,
                        ]), // Hapus dari centang jika ada
                      });
                }
              },
            ),
            const SizedBox(width: 16),

            // TOMBOL CENTANG (MUTUAL EXCLUSIVE)
            _buildAction(
              hasVotedCorrect ? Icons.check_circle : Icons.check_circle_outline,
              hasVotedCorrect ? Colors.green : Colors.black87,
              correctVoters.length.toString(),
              () {
                if (currentUid == null) return;
                if (hasVotedCorrect) {
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .update({
                        'correctVoters': FieldValue.arrayRemove([currentUid]),
                      });
                } else {
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .update({
                        'correctVoters': FieldValue.arrayUnion([currentUid]),
                        'incorrectVoters': FieldValue.arrayRemove([
                          currentUid,
                        ]), // Hapus dari silang jika ada
                      });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text("$username $caption", style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildAction(
    IconData icon,
    Color color,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
