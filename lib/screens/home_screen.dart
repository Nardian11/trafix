import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // IMPORT SUDAH DIPERBAIKI (TIDAK TYPO LAGI)
import 'detail_post_screen.dart';
import 'notification_screen.dart';
import 'add_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor dihapus agar otomatis mengikuti Dark/Light Mode
      appBar: AppBar(
        // backgroundColor dihapus
        elevation: 0,
        leading: IconButton(
          // color: Colors.black dihapus, otomatis mengikuti tema AppBar
          icon: const Icon(Icons.add_circle_outline, size: 28),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPostScreen())),
        ),
        // color: Colors.black dihapus pada Text
        title: const Text('Trafix', style: TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            // color: Colors.black dihapus
            icon: const Icon(Icons.notifications_none, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada laporan.', 
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
              ),
            );
          }

          var posts = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var postData = posts[index].data() as Map<String, dynamic>;
              
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
    super.key, required this.postId, required this.name, required this.username,
    required this.location, required this.caption, required this.imageBase64,
    required this.likedVoters, required this.correctVoters, required this.incorrectVoters,
    required this.commentsCount,
  });

  @override
  Widget build(BuildContext context) {
    String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    bool hasLiked = likedVoters.contains(currentUid);
    bool hasVotedCorrect = correctVoters.contains(currentUid);
    bool hasVotedIncorrect = incorrectVoters.contains(currentUid);
    
    // Ambil warna ikon default dari tema (Hitam saat terang, Putih saat gelap)
    Color defaultIconColor = Theme.of(context).iconTheme.color ?? Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18, 
              backgroundColor: Colors.grey.withOpacity(0.3), 
              backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11')
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  location, 
                  style: TextStyle(
                    fontSize: 10, 
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), // Dinamis
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
                ? Image.memory(base64Decode(imageBase64), height: 200, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 200, color: Colors.grey.withOpacity(0.2), child: const Icon(Icons.image_not_supported)),
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            // TOMBOL LIKE INDEPENDEN (SUDAH DITAMBAHKAN ASYNC AWAIT)
            _buildAction(
              hasLiked ? Icons.favorite : Icons.favorite_border, 
              hasLiked ? Colors.red : defaultIconColor, 
              likedVoters.length.toString(), 
              () async { // <--- ASYNC DITAMBAHKAN
                if (currentUid == null) return;
                
                String rawLocation = location.toLowerCase();
                List<String> locationWords = rawLocation.split(RegExp(r'[\s,.]+'));
                String targetedTopic = "umum"; 
                for (var word in locationWords) {
                  if (word.length > 3 && word != 'jalan' && word != 'gang' && word != 'raya' && word != 'jln') {
                    targetedTopic = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
                    break;
                  }
                }

                if (hasLiked) {
                  // <--- AWAIT DITAMBAHKAN
                  await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                    'likedVoters': FieldValue.arrayRemove([currentUid])
                  });
                  await FirebaseMessaging.instance.unsubscribeFromTopic("jalan_$targetedTopic");
                } else {
                  // <--- AWAIT DITAMBAHKAN
                  await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                    'likedVoters': FieldValue.arrayUnion([currentUid])
                  });
                  await FirebaseMessaging.instance.subscribeToTopic("jalan_$targetedTopic");
                }
              }
            ),
            const SizedBox(width: 16),
            
            // INDIKATOR BALASAN / KOMENTAR NYATA
            _buildAction(
              Icons.chat_bubble_outline, 
              defaultIconColor, 
              '$commentsCount Balasan', 
              () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPostScreen(postId: postId, name: name, username: username, location: location, caption: caption, imageBase64: imageBase64)));
              }
            ),
            const SizedBox(width: 16),
            
            // TOMBOL X (MUTUAL EXCLUSIVE TERHADAP CENTANG, SUDAH DITAMBAHKAN ASYNC AWAIT)
            _buildAction(
              hasVotedIncorrect ? Icons.cancel : Icons.cancel_outlined, 
              hasVotedIncorrect ? Colors.red : defaultIconColor, 
              incorrectVoters.length.toString(), 
              () async { // <--- ASYNC DITAMBAHKAN
                if (currentUid == null) return;
                if (hasVotedIncorrect) {
                  await FirebaseFirestore.instance.collection('posts').doc(postId).update({'incorrectVoters': FieldValue.arrayRemove([currentUid])});
                } else {
                  await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                    'incorrectVoters': FieldValue.arrayUnion([currentUid]),
                    'correctVoters': FieldValue.arrayRemove([currentUid])
                  });
                }
              }
            ),
            const SizedBox(width: 16),
            
            // TOMBOL CENTANG (MUTUAL EXCLUSIVE TERHADAP X, SUDAH DITAMBAHKAN ASYNC AWAIT)
            _buildAction(
              hasVotedCorrect ? Icons.check_circle : Icons.check_circle_outline, 
              hasVotedCorrect ? Colors.green : defaultIconColor, 
              correctVoters.length.toString(), 
              () async { // <--- ASYNC DITAMBAHKAN
                if (currentUid == null) return;
                if (hasVotedCorrect) {
                  await FirebaseFirestore.instance.collection('posts').doc(postId).update({'correctVoters': FieldValue.arrayRemove([currentUid])});
                } else {
                  await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                    'correctVoters': FieldValue.arrayUnion([currentUid]),
                    'incorrectVoters': FieldValue.arrayRemove([currentUid])
                  });
                }
              }
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "$username $caption", 
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).textTheme.bodyLarge?.color, // Warna teks dinamis
          ),
        ),
      ],
    );
  }

  Widget _buildAction(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24), 
          Text(label, style: TextStyle(fontSize: 10, color: color)) // Warna teks mengikuti warna ikon
        ],
      ),
    );
  }
}