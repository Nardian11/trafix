import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'detail_post_screen.dart';
import 'notification_screen.dart';
import 'add_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 28),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          ),
        ),
        title: const Text(
          'Trafix',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==============================================================
          // 1. HEADER PROFIL REAL-TIME MENGGUNAKAN STREAM BUILDER
          // ==============================================================
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              var userData = userSnapshot.data!.data() as Map<String, dynamic>;
              String currentUsername = userData['username'] ?? 'User';
              String currentProfilePic = userData['profilePic'] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      backgroundImage: currentProfilePic.isNotEmpty
                          ? MemoryImage(base64Decode(currentProfilePic))
                                as ImageProvider
                          : const NetworkImage(
                              'https://i.pravatar.cc/150?img=11',
                            ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang,',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          currentUsername,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // ==============================================================
          // 2. TIMELINE POSTINGAN
          // ==============================================================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                      'Belum ada laporan.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  );
                }

                var posts = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var postData = posts[index].data() as Map<String, dynamic>;

                    List<dynamic> likedVoters = postData['likedVoters'] ?? [];
                    List<dynamic> correctVoters =
                        postData['correctVoters'] ?? [];
                    List<dynamic> incorrectVoters =
                        postData['incorrectVoters'] ?? [];
                    int commentsCount = postData['commentsCount'] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: PostCardWidget(
                        postId: posts[index].id,
                        postUid:
                            postData['uid'] ??
                            '', // <--- MENGIRIMKAN UID SI PEMBUAT POSTINGAN
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
          ),
        ],
      ),
    );
  }
}

class PostCardWidget extends StatelessWidget {
  // name dan username dihapus, diganti dengan postUid
  final String postId, postUid, location, caption, imageBase64;
  final List<dynamic> likedVoters;
  final List<dynamic> correctVoters;
  final List<dynamic> incorrectVoters;
  final int commentsCount;

  const PostCardWidget({
    super.key,
    required this.postId,
    required this.postUid,
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

    Color defaultIconColor = Theme.of(context).iconTheme.color ?? Colors.grey;

    // ==========================================================
    // KUNCI JAWABAN: MEMBUNGKUS POST CARD DENGAN STREAM BUILDER
    // Agar mengambil nama & foto profil TERBARU berdasarkan postUid
    // ==========================================================
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(postUid)
          .snapshots(),
      builder: (context, userSnapshot) {
        String authorName = "Memuat...";
        String authorProfilePic = "";

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var authorData = userSnapshot.data!.data() as Map<String, dynamic>;
          authorName = authorData['username'] ?? 'Anonim';
          authorProfilePic = authorData['profilePic'] ?? '';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  backgroundImage: authorProfilePic.isNotEmpty
                      ? MemoryImage(base64Decode(authorProfilePic))
                            as ImageProvider
                      : const NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPostScreen(
                      postId: postId,
                      name:
                          authorName, // <--- Melempar nama terbaru ke Detail Screen
                      username:
                          authorName, // <--- Melempar username terbaru ke Detail Screen
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
                        color: Colors.grey.withOpacity(0.2),
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // TOMBOL LIKE
                _buildAction(
                  hasLiked ? Icons.favorite : Icons.favorite_border,
                  hasLiked ? Colors.red : defaultIconColor,
                  likedVoters.length.toString(),
                  () async {
                    if (currentUid == null) return;

                    String rawLocation = location.toLowerCase();
                    List<String> locationWords = rawLocation.split(
                      RegExp(r'[\s,.]+'),
                    );
                    String targetedTopic = "umum";
                    for (var word in locationWords) {
                      if (word.length > 3 &&
                          word != 'jalan' &&
                          word != 'gang' &&
                          word != 'raya' &&
                          word != 'jln') {
                        targetedTopic = word.replaceAll(
                          RegExp(r'[^a-zA-Z0-9]'),
                          '',
                        );
                        break;
                      }
                    }

                    if (hasLiked) {
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .update({
                            'likedVoters': FieldValue.arrayRemove([currentUid]),
                          });
                      await FirebaseMessaging.instance.unsubscribeFromTopic(
                        "jalan_$targetedTopic",
                      );
                    } else {
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .update({
                            'likedVoters': FieldValue.arrayUnion([currentUid]),
                          });
                      await FirebaseMessaging.instance.subscribeToTopic(
                        "jalan_$targetedTopic",
                      );
                    }
                  },
                ),
                const SizedBox(width: 16),

                // TOMBOL KOMENTAR
                _buildAction(
                  Icons.chat_bubble_outline,
                  defaultIconColor,
                  '$commentsCount Balasan',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPostScreen(
                          postId: postId,
                          name: authorName,
                          username: authorName,
                          location: location,
                          caption: caption,
                          imageBase64: imageBase64,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),

                // TOMBOL X
                _buildAction(
                  hasVotedIncorrect ? Icons.cancel : Icons.cancel_outlined,
                  hasVotedIncorrect ? Colors.red : defaultIconColor,
                  incorrectVoters.length.toString(),
                  () async {
                    if (currentUid == null) return;
                    if (hasVotedIncorrect) {
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .update({
                            'incorrectVoters': FieldValue.arrayRemove([
                              currentUid,
                            ]),
                          });
                    } else {
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .update({
                            'incorrectVoters': FieldValue.arrayUnion([
                              currentUid,
                            ]),
                            'correctVoters': FieldValue.arrayRemove([
                              currentUid,
                            ]),
                          });
                    }
                  },
                ),
                const SizedBox(width: 16),

                // TOMBOL CENTANG
                _buildAction(
                  hasVotedCorrect
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  hasVotedCorrect ? Colors.green : defaultIconColor,
                  correctVoters.length.toString(),
                  () async {
                    if (currentUid == null) return;
                    if (hasVotedCorrect) {
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .update({
                            'correctVoters': FieldValue.arrayRemove([
                              currentUid,
                            ]),
                          });
                    } else {
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .update({
                            'correctVoters': FieldValue.arrayUnion([
                              currentUid,
                            ]),
                            'incorrectVoters': FieldValue.arrayRemove([
                              currentUid,
                            ]),
                          });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ==========================================================
            // KUNCI JAWABAN: MENGGUNAKAN RICHTEXT UNTUK USERNAME BOLD
            // ==========================================================
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                children: [
                  TextSpan(
                    text: "$authorName ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: caption),
                ],
              ),
            ),
          ],
        );
      },
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
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}
