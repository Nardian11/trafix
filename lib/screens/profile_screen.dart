import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';       // IJIN MASUK: Untuk Log Out & Cek User
import 'package:cloud_firestore/cloud_firestore.dart';   // IJIN MASUK: Untuk Tarik Data User
import 'edit_profile_screen.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ========================================================
  // LOGIKA UTAMA: LOG OUT
  // ========================================================
  Future<void> _logOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Hapus sesi login dari HP
      
      if (context.mounted) {
        // Lempar kembali ke Sign In dan bersihkan semua riwayat layar (tidak bisa di-back)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal Log Out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil info user yang sedang login saat ini
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          Switch(
            value: false, // Nanti bisa dipakai untuk fitur Dark Mode
            onChanged: (value) {},
            activeColor: Colors.black,
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: Colors.grey.shade300,
          ),
          const SizedBox(width: 16),
        ],
      ),
      // ========================================================
      // LOGIKA UTAMA: MENARIK DATA DARI FIRESTORE
      // ========================================================
      body: currentUser == null
          ? const Center(child: Text('Tidak ada pengguna yang login.'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
              builder: (context, snapshot) {
                // 1. Saat data sedang ditarik dari server
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1E2F3E)));
                }

                // 2. Jika error jaringan
                if (snapshot.hasError) {
                  return const Center(child: Text('Gagal memuat profil.'));
                }

                // 3. Jika data berhasil didapat
                if (snapshot.hasData && snapshot.data!.exists) {
                  var userData = snapshot.data!.data() as Map<String, dynamic>;
                  
                  // Tarik field dari database, jika kosong beri nilai default
                  String username = userData['username'] ?? 'No Username';
                  String email = userData['email'] ?? currentUser.email ?? 'No Email';
                  String phone = userData['phone'] ?? 'No Phone Number';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 45,
                          // Nanti bisa diganti dengan foto profil asli dari Firestore Storage
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'), 
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2F3E), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            elevation: 0,
                          ),
                          child: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(height: 32),
                        
                        // Menampilkan data dinamis dari database!
                        _buildReadOnlyField('Username', username),
                        const SizedBox(height: 16),
                        _buildReadOnlyField('Email address', email),
                        const SizedBox(height: 16),
                        _buildReadOnlyField('Phone Number', phone),
                        
                        const SizedBox(height: 40),
                        
                        // TOMBOL LOG OUT ASLI
                        ElevatedButton(
                          onPressed: () => _logOut(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            elevation: 0,
                          ),
                          child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }

                // Jika dokumen user tidak ditemukan di database
                return const Center(child: Text('Data profil tidak ditemukan.'));
              },
            ),
    );
  }

  // Komponen pembentuk form read-only
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.transparent, 
            border: Border.all(color: const Color(0xFF8D8D8D)), 
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        ),
      ],
    );
  }
}