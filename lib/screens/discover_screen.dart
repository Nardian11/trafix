import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // IJIN MASUK: Database Firestore
import 'home_screen.dart'; // IJIN MASUK: Meminjam PostCardWidget dari layar Home

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String searchQuery = ""; // Variabel untuk menyimpan teks yang sedang diketik user
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            // ========================================================
            // 1. KOTAK PENCARIAN (SEARCH BAR)
            // ========================================================
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E2E2), 
                  borderRadius: BorderRadius.circular(30.0), 
                ),
                child: TextField(
                  controller: _searchController,
                  // LOGIKA OTOMATIS: Setiap kali user mengetik, jalankan ini
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase(); // Ubah ke huruf kecil semua agar pencarian akurat
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter street name',
                    hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Memunculkan tombol silang (X) hanya jika kotak pencarian ada isinya
                        if (searchQuery.isNotEmpty) 
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black45, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = ""; // Hapus pencarian dan tampilkan semua data lagi
                              });
                            }, 
                          ),
                        const Icon(Icons.search, color: Colors.black87, size: 20),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // ========================================================
            // 2. HASIL PENCARIAN DARI FIRESTORE
            // ========================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  // Jika masih loading mengambil data awal
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF1E2F3E)));
                  }

                  // Jika database kosong
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Belum ada data laporan lalu lintas.'));
                  }

                  // LOGIKA FILTERING (Penyaringan Berdasarkan Ketikan)
                  var allPosts = snapshot.data!.docs;
                  var filteredPosts = allPosts.where((post) {
                    var location = post['location'].toString().toLowerCase();
                    return location.contains(searchQuery); // Cek apakah nama jalan cocok dengan ketikan
                  }).toList();

                  // Jika hasil pencarian tidak ditemukan
                  if (filteredPosts.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada laporan untuk jalan "$searchQuery"',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  // Cetak hasil pencarian
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      var postData = filteredPosts[index].data() as Map<String, dynamic>;
                      var postId = filteredPosts[index].id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        // Menggunakan ulang desain kartu dari home_screen.dart!
                        child: PostCardWidget(
                          postId: postId,
                          name: postData['name'] ?? 'Anonim',
                          username: postData['username'] ?? 'anonim',
                          location: postData['location'] ?? 'Lokasi tidak diketahui',
                          caption: postData['caption'] ?? '',
                          imageUrl: postData['imageUrl'] ?? 'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=800&q=80',
                          likesCount: postData['likesCount'] ?? 0,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}