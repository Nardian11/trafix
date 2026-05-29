import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_post_screen.dart'; // Wajib import agar bisa pindah halaman

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String searchQuery = ''; // Variabel penyimpan teks pencarian

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextField(
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari nama jalan macet...',
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              border: InputBorder.none,
              icon: Icon(
                Icons.search,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // ==============================================================
          // KUNCI JAWABAN: JIKA SEARCH BAR KOSONG, TAMPILKAN LAYAR BERSIH
          // ==============================================================
          if (searchQuery.trim().isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 80,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ketik nama jalan untuk mencari laporan.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

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
                'Belum ada laporan di database.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            );
          }

          var posts = snapshot.data!.docs;

          // LOGIKA FILTER PENCARIAN (Berdasarkan Lokasi atau Caption)
          posts = posts.where((post) {
            var data = post.data() as Map<String, dynamic>;
            var location = (data['location'] ?? '').toString().toLowerCase();
            var caption = (data['caption'] ?? '').toString().toLowerCase();
            return location.contains(searchQuery) ||
                caption.contains(searchQuery);
          }).toList();

          // Jika setelah dicari ternyata tidak ada jalan/caption yang cocok
          if (posts.isEmpty) {
            return Center(
              child: Text(
                'Laporan tidak ditemukan.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Kolom sejajar
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75, // Rasio portrait
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var postData = posts[index].data() as Map<String, dynamic>;
              String imgBase64 = postData['image'] ?? '';
              String postId = posts[index].id;

              return GestureDetector(
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
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Layer Bawah: Gambar Base64
                      imgBase64.isNotEmpty
                          ? Image.memory(
                              base64Decode(imgBase64),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey.withOpacity(0.2),
                              child: Icon(
                                Icons.image,
                                color: Theme.of(
                                  context,
                                ).iconTheme.color?.withOpacity(0.3),
                              ),
                            ),

                      // 2. Layer Atas: Efek Gradient & Teks Lokasi
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  postData['location'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
