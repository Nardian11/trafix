import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailPostScreen extends StatefulWidget {
  final String postId, name, username, location, caption, imageBase64;
  // ==========================================================
  // KUNCI JAWABAN 1: TAMBAHKAN PARAMETER UID PENGUNGGAH
  // ==========================================================
  final String? postUid;

  const DetailPostScreen({
    super.key,
    required this.postId,
    required this.name,
    required this.username,
    required this.location,
    required this.caption,
    required this.imageBase64,
    this.postUid, // Jadikan opsional agar tidak merusak kodingan lama yang belum mengirim ini
  });

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _redirectToGoogleMaps(String locationName) async {
    final String mapUrl =
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationName)}";
    final Uri url = Uri.parse(mapUrl);

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka Google Maps: $e')));
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    String currentUsername = userDoc['username'] ?? 'User';

    // Simpan ke sub-koleksi komentar
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
          'uid': currentUser.uid, // <-- INI PENTING UNTUK FOTO PROFIL KOMENTAR
          'username': currentUsername,
          'text': _commentController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Sinkronisasi naikkan counter ke Beranda
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'commentsCount': FieldValue.increment(1)});

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
    Color defaultIconColor = Theme.of(context).iconTheme.color ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Laporan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }

                    var postData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    List<dynamic> likedVoters = postData['likedVoters'] ?? [];
                    List<dynamic> correctVoters =
                        postData['correctVoters'] ?? [];
                    List<dynamic> incorrectVoters =
                        postData['incorrectVoters'] ?? [];
                    String currentImage =
                        postData['image'] ?? widget.imageBase64;
                    // Ambil UID pengunggah dari database post jika di widget belum dikirim
                    String actualPostUid =
                        widget.postUid ?? (postData['uid'] ?? '');

                    bool hasLiked = likedVoters.contains(currentUid);
                    bool hasVotedCorrect = correctVoters.contains(currentUid);
                    bool hasVotedIncorrect = incorrectVoters.contains(
                      currentUid,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==========================================================
                        // KUNCI JAWABAN 2: STREAM BUILDER UNTUK FOTO PENGUNGGAH
                        // ==========================================================
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(actualPostUid)
                              .snapshots(),
                          builder: (context, authorSnapshot) {
                            String authorPic = '';
                            String authorName =
                                widget.name; // Fallback ke parameter

                            if (authorSnapshot.hasData &&
                                authorSnapshot.data!.exists) {
                              var authorData =
                                  authorSnapshot.data!.data()
                                      as Map<String, dynamic>;
                              authorPic = authorData['profilePic'] ?? '';
                              authorName = authorData['username'] ?? authorName;
                            }

                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey.withOpacity(0.3),
                                  backgroundImage: authorPic.isNotEmpty
                                      ? MemoryImage(base64Decode(authorPic))
                                            as ImageProvider
                                      : const NetworkImage(
                                          'https://i.pravatar.cc/150?img=11',
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        widget.location,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _redirectToGoogleMaps(widget.location),
                                  icon: const Icon(Icons.map, size: 16),
                                  label: const Text(
                                    'Maps',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: currentImage.isNotEmpty
                              ? Image.memory(
                                  base64Decode(currentImage),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 250,
                                  color: Colors.grey.withOpacity(0.2),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Theme.of(
                                      context,
                                    ).iconTheme.color?.withOpacity(0.3),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (currentUid == null) return;

                                String rawLocation = widget.location
                                    .toLowerCase();
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
                                      .doc(widget.postId)
                                      .update({
                                        'likedVoters': FieldValue.arrayRemove([
                                          currentUid,
                                        ]),
                                      });
                                  await FirebaseMessaging.instance
                                      .unsubscribeFromTopic(
                                        "jalan_$targetedTopic",
                                      );
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.postId)
                                      .update({
                                        'likedVoters': FieldValue.arrayUnion([
                                          currentUid,
                                        ]),
                                      });
                                  await FirebaseMessaging.instance
                                      .subscribeToTopic("jalan_$targetedTopic");
                                }
                              },
                              child: _buildActionIcon(
                                hasLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                hasLiked ? Colors.red : defaultIconColor,
                                likedVoters.length.toString(),
                              ),
                            ),
                            const SizedBox(width: 32),
                            GestureDetector(
                              onTap: () async {
                                if (currentUid == null) return;
                                if (hasVotedIncorrect) {
                                  await FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.postId)
                                      .update({
                                        'incorrectVoters':
                                            FieldValue.arrayRemove([
                                              currentUid,
                                            ]),
                                      });
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.postId)
                                      .update({
                                        'incorrectVoters':
                                            FieldValue.arrayUnion([currentUid]),
                                        'correctVoters': FieldValue.arrayRemove(
                                          [currentUid],
                                        ),
                                      });
                                }
                              },
                              child: _buildActionIcon(
                                hasVotedIncorrect
                                    ? Icons.cancel
                                    : Icons.cancel_outlined,
                                hasVotedIncorrect
                                    ? Colors.red
                                    : defaultIconColor,
                                incorrectVoters.length.toString(),
                              ),
                            ),
                            const SizedBox(width: 32),
                            GestureDetector(
                              onTap: () async {
                                if (currentUid == null) return;
                                if (hasVotedCorrect) {
                                  await FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.postId)
                                      .update({
                                        'correctVoters': FieldValue.arrayRemove(
                                          [currentUid],
                                        ),
                                      });
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(widget.postId)
                                      .update({
                                        'correctVoters': FieldValue.arrayUnion([
                                          currentUid,
                                        ]),
                                        'incorrectVoters':
                                            FieldValue.arrayRemove([
                                              currentUid,
                                            ]),
                                      });
                                }
                              },
                              child: _buildActionIcon(
                                hasVotedCorrect
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                hasVotedCorrect
                                    ? Colors.green
                                    : defaultIconColor,
                                correctVoters.length.toString(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontSize: 14,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: '${widget.username} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: widget.caption),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(
                    thickness: 1,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                const Text(
                  "Komentar",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                // SISTEM CHAT KOMENTAR DI BAWAH DETAIL POST
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Belum ada komentar.",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                        ),
                      );
                    }
                    var comments = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        var commentData =
                            comments[index].data() as Map<String, dynamic>;
                        String commentUid =
                            commentData['uid'] ??
                            ''; // Tarik UID sang komentator

                        // ==========================================================
                        // KUNCI JAWABAN 3: STREAM BUILDER UNTUK FOTO TIAP KOMENTATOR
                        // ==========================================================
                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(commentUid)
                              .snapshots(),
                          builder: (context, commenterSnapshot) {
                            String commenterPic = '';
                            String commenterName =
                                commentData['username'] ?? 'Seseorang';

                            if (commenterSnapshot.hasData &&
                                commenterSnapshot.data!.exists) {
                              var cData =
                                  commenterSnapshot.data!.data()
                                      as Map<String, dynamic>;
                              commenterPic = cData['profilePic'] ?? '';
                              commenterName =
                                  cData['username'] ?? commenterName;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // FOTO PROFIL KOMENTATOR
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.grey.withOpacity(
                                      0.3,
                                    ),
                                    backgroundImage: commenterPic.isNotEmpty
                                        ? MemoryImage(
                                                base64Decode(commenterPic),
                                              )
                                              as ImageProvider
                                        : const NetworkImage(
                                            'https://i.pravatar.cc/150?img=11',
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "$commenterName ",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(text: commentData['text']),
                                        ],
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
              ],
            ),
          ),

          // ==========================================================
          // KUNCI JAWABAN 4: FOTO PROFIL KITA SENDIRI DI BAR KOMENTAR BAWAH
          // ==========================================================
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUid)
                .snapshots(),
            builder: (context, mySnapshot) {
              String myPic = '';
              if (mySnapshot.hasData && mySnapshot.data!.exists) {
                myPic =
                    (mySnapshot.data!.data()
                        as Map<String, dynamic>)['profilePic'] ??
                    '';
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black26
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        backgroundImage: myPic.isNotEmpty
                            ? MemoryImage(base64Decode(myPic)) as ImageProvider
                            : const NetworkImage(
                                'https://i.pravatar.cc/150?img=11',
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Tambahkan komentar...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: _postComment,
                      ),
                    ],
                  ),
                ),
              );
            },
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
