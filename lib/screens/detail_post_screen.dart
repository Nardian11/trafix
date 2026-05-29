import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailPostScreen extends StatefulWidget {
  final String postId, name, username, location, caption, imageBase64;

  const DetailPostScreen({
    super.key, required this.postId, required this.name, required this.username,
    required this.location, required this.caption, required this.imageBase64,
  });

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  final TextEditingController _commentController = TextEditingController();

  // ROUTING GOOGLE MAPS TANPA CANLAUNCH (BYPASS ERROR)
  Future<void> _redirectToGoogleMaps(String locationName) async {
    final String mapUrl = "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationName)}";
    final Uri url = Uri.parse(mapUrl);

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka Google Maps: $e')),
      );
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    String currentUsername = userDoc['username'] ?? 'User';

    // Simpan ke sub-koleksi komentar
    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
      'uid': currentUser.uid,
      'username': currentUsername,
      'text': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Sinkronisasi naikkan counter ke Beranda
    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
      'commentsCount': FieldValue.increment(1),
    });

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Laporan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());

                    var postData = snapshot.data!.data() as Map<String, dynamic>;
                    List<dynamic> likedVoters = postData['likedVoters'] ?? [];
                    List<dynamic> correctVoters = postData['correctVoters'] ?? [];
                    List<dynamic> incorrectVoters = postData['incorrectVoters'] ?? [];
                    String currentImage = postData['image'] ?? widget.imageBase64;

                    bool hasLiked = likedVoters.contains(currentUid);
                    bool hasVotedCorrect = correctVoters.contains(currentUid);
                    bool hasVotedIncorrect = incorrectVoters.contains(currentUid);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(radius: 20, backgroundColor: Colors.grey, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(widget.location, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _redirectToGoogleMaps(widget.location),
                              icon: const Icon(Icons.map, size: 16, color: Colors.white),
                              label: const Text('Maps', style: TextStyle(fontSize: 12, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E2F3E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: currentImage.isNotEmpty
                              ? Image.memory(base64Decode(currentImage), width: double.infinity, fit: BoxFit.cover)
                              : Container(height: 250, color: Colors.grey, child: const Icon(Icons.image_not_supported)),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            // LIKE SINKRON DENGAN HOME
                            GestureDetector(
                              onTap: () {
                                if (currentUid == null) return;
                                
                                String rawLocation = widget.location.toLowerCase();
                                List<String> locationWords = rawLocation.split(RegExp(r'[\s,.]+'));
                                String targetedTopic = "umum"; 
                                for (var word in locationWords) {
                                  if (word.length > 3 && word != 'jalan' && word != 'gang' && word != 'raya' && word != 'jln') {
                                    targetedTopic = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
                                    break;
                                  }
                                }

                                if (hasLiked) {
                                  FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
                                    'likedVoters': FieldValue.arrayRemove([currentUid])
                                  });
                                  FirebaseMessaging.instance.unsubscribeFromTopic("jalan_$targetedTopic");
                                } else {
                                  FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
                                    'likedVoters': FieldValue.arrayUnion([currentUid])
                                  });
                                  FirebaseMessaging.instance.subscribeToTopic("jalan_$targetedTopic");
                                }
                              },
                              child: _buildActionIcon(hasLiked ? Icons.favorite : Icons.favorite_border, hasLiked ? Colors.red : Colors.black87, likedVoters.length.toString()),
                            ),
                            const SizedBox(width: 32),
                            // BUTTON SILANG SINKRON DENGAN HOME
                            GestureDetector(
                              onTap: () {
                                if (currentUid == null) return;
                                if (hasVotedIncorrect) {
                                  FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({'incorrectVoters': FieldValue.arrayRemove([currentUid])});
                                } else {
                                  FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
                                    'incorrectVoters': FieldValue.arrayUnion([currentUid]),
                                    'correctVoters': FieldValue.arrayRemove([currentUid])
                                  });
                                }
                              },
                              child: _buildActionIcon(hasVotedIncorrect ? Icons.cancel : Icons.cancel_outlined, hasVotedIncorrect ? Colors.red : Colors.redAccent, incorrectVoters.length.toString()),
                            ),
                            const SizedBox(width: 32),
                            // BUTTON CENTANG SINKRON DENGAN HOME
                            GestureDetector(
                              onTap: () {
                                if (currentUid == null) return;
                                if (hasVotedCorrect) {
                                  FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({'correctVoters': FieldValue.arrayRemove([currentUid])});
                                } else {
                                  FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
                                    'correctVoters': FieldValue.arrayUnion([currentUid]),
                                    'incorrectVoters': FieldValue.arrayRemove([currentUid])
                                  });
                                }
                              },
                              child: _buildActionIcon(hasVotedCorrect ? Icons.check_circle : Icons.check_circle_outline, hasVotedCorrect ? Colors.green : Colors.black87, correctVoters.length.toString()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.5),
                            children: [
                              TextSpan(text: '${widget.username} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: widget.caption),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(thickness: 1)),
                const Text("Komentar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                
                // SISTEM CHAT KOMENTAR DI BAWAH DETAIL POST
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').orderBy('timestamp', descending: false).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(padding: EdgeInsets.all(16.0), child: Text("Belum ada komentar.", style: TextStyle(color: Colors.black54)));
                    }
                    var comments = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        var commentData = comments[index].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black, fontSize: 13, height: 1.4),
                              children: [
                                TextSpan(text: "${commentData['username']} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: commentData['text']),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          
          // PINNED BAR INPUT TEXT KOMENTAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: SafeArea(
              child: Row(
                children: [
                  const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: 'Tambahkan komentar...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14)), maxLines: null)),
                  IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _postComment),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
      ],
    );
  }
}