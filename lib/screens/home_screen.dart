import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_post_screen.dart';
import 'notification_screen.dart';
import 'add_post_screen.dart';
import 'comment_screen.dart';

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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPostScreen()),
            );
          },
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      // ========================================================
      // LOGIKA UTAMA: MENARIK DATA POSTINGAN DARI FIRESTORE
      // ========================================================
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E2F3E)),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan memuat data.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada laporan lalu lintas.\nJadilah yang pertama melapor!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
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
              var postId = posts[index].id; 

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: PostCardWidget(
                  postId: postId,
                  name: postData['name'] ?? 'Anonim',
                  username: postData['username'] ?? 'anonim',
                  location: postData['location'] ?? 'Lokasi tidak diketahui',
                  caption: postData['caption'] ?? '',
                  imageUrl:
                      postData['imageUrl'] ??
                      'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=800&q=80',
                  likesCount: postData['likesCount'] ?? 0,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ========================================================
// KARTU POSTINGAN
// ========================================================
class PostCardWidget extends StatefulWidget {
  final String postId; 
  final String name;
  final String username;
  final String location;
  final String caption;
  final String imageUrl;
  final int likesCount;

  const PostCardWidget({
    super.key,
    required this.postId,
    required this.name,
    required this.username,
    required this.location,
    required this.caption,
    required this.imageUrl,
    required this.likesCount,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  bool _isLiked = false;
  late int _currentLikeCount;

  @override
  void initState() {
    super.initState();
    _currentLikeCount = widget.likesCount; 
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Post
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPostScreen(
                  postId: widget.postId,
                  name: widget.name,
                  username: widget.username,
                  location: widget.location,
                  caption: widget.caption,
                  imageUrl: widget.imageUrl,
                  likesCount: widget.likesCount,
                ),
              ),
            );
          },
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=11',
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    widget.location,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.remove_circle_outline,
                color: Colors.black38,
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Gambar Laporan 
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPostScreen(
                  postId: widget.postId,
                  name: widget.name,
                  username: widget.username,
                  location: widget.location,
                  caption: widget.caption,
                  imageUrl: widget.imageUrl,
                  likesCount: widget.likesCount,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              widget.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Baris Aksi
        Row(
          children: [
            // LOGIKA TOMBOL LIKE YANG BARU DITAMBAHKAN
            GestureDetector(
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                setState(() {
                  _isLiked = !_isLiked;
                  _isLiked ? _currentLikeCount++ : _currentLikeCount--;
                });

                // Referensi path database favorites milik user yang sedang login
                final favRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('favorites')
                    .doc(widget.postId);

                if (_isLiked) {
                  // 1. Catat ke database favorites user
                  await favRef.set({
                    'postId': widget.postId,
                    'location': widget.location,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  
                  // 2. Update total likes di dokumen posts utama
                  FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
                    'likesCount': FieldValue.increment(1)
                  });

                  print('Menembak API ke Vercel untuk lokasi: ${widget.location}');
                } else {
                  // Jika di-unlike, hapus dari folder favorites user
                  await favRef.delete();

                  // Kurangi total likes di dokumen posts utama
                  FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
                    'likesCount': FieldValue.increment(-1)
                  });
                }
              },
              child: Column(
                children: [
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.black87,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_currentLikeCount',
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // TOMBOL KOMENTAR
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommentScreen(postId: widget.postId),
                  ),
                );
              },
              child: _buildStaticActionIcon(
                Icons.chat_bubble_outline,
                Colors.black87,
                'Balas',
              ),
            ),
            const SizedBox(width: 16),

            _buildStaticActionIcon(Icons.cancel_outlined, Colors.black87, '2'),
            const SizedBox(width: 16),
            _buildStaticActionIcon(
              Icons.check_circle_outline,
              Colors.black87,
              '5',
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Teks Caption
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: '${widget.username} ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: widget.caption),
              const TextSpan(
                text: ' more',
                style: TextStyle(color: Colors.black38),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaticActionIcon(IconData icon, Color color, String count) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
      ],
    );
  }
}