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
      // backgroundColor DIHAPUS agar otomatis ikut tema
      appBar: AppBar(
        // backgroundColor DIHAPUS
        elevation: 0,
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            // Warna background search bar otomatis menyesuaikan warna Card di tema
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            // Tambahan border tipis agar lebih bertekstur
            border: Border.all(color: Colors.grey.withOpacity(0.2)), 
          ),
          child: TextField(
            // Warna teks yang diketik dinamis
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            // TRIGGER PENCARIAN SECARA REAL-TIME SAAT DIKETIK
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari nama jalan macet...',
              hintStyle: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), // Hint dinamis
              ),
              border: InputBorder.none,
              icon: Icon(
                Icons.search, 
                color: Theme.of(context).iconTheme.color?.withOpacity(0.6), // Ikon search dinamis
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil semua data postingan, urutkan dari yang terbaru
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary), // Loading dinamis
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada laporan untuk di-discover.',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)), // Teks dinamis
              ),
            );
          }

          var posts = snapshot.data!.docs;

          // LOGIKA FILTER PENCARIAN (Berdasarkan Lokasi atau Caption)
          if (searchQuery.isNotEmpty) {
            posts = posts.where((post) {
              var data = post.data() as Map<String, dynamic>;
              var location = (data['location'] ?? '').toString().toLowerCase();
              var caption = (data['caption'] ?? '').toString().toLowerCase();
              return location.contains(searchQuery) ||
                  caption.contains(searchQuery);
            }).toList();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Kolom sejajar
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio:
                  0.75, // Rasio portrait agar gambar lebih proporsional (tidak kaku)
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var postData = posts[index].data() as Map<String, dynamic>;
              String imgBase64 = postData['image'] ?? '';
              String postId = posts[index].id;

              return GestureDetector(
                onTap: () {
                  // LEMPAR DATA KE DETAIL SCREEN SAAT DITEKAN
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
                              color: Colors.grey.withOpacity(0.2), // Background placeholder dinamis transparan
                              child: Icon(
                                Icons.image, 
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.3) // Ikon dinamis transparan
                              ),
                            ),

                      // 2. Layer Atas: Efek Gradient & Teks Lokasi
                      // Bagian ini TETAP menggunakan warna statis (Black ke Transparent & text White)
                      // Karena ini overlay di atas gambar, jadi tetap butuh teks putih agar selalu terbaca.
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
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  postData['location'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1, // Dibatasi 1 baris agar rapi
                                  overflow: TextOverflow
                                      .ellipsis, // Jika kepanjangan jadi titik-titik
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