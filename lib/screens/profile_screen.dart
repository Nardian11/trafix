import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import 'edit_profile_screen.dart'; // Pastikan import ini benar

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profil Saya", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Data tidak ditemukan"));
          
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String profileBase64 = userData['profilePic'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profileBase64.isNotEmpty 
                    ? MemoryImage(base64Decode(profileBase64)) as ImageProvider
                    : const NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
                const SizedBox(height: 15),
                Text(userData['username'] ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                // TOMBOL PINDAH KE HALAMAN EDIT PROFIL
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text("Edit Profil & Foto"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                  },
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(height: 12),

                // TOGGLE DARK MODE
                SwitchListTile(
                  secondary: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                  title: const Text("Mode Gelap"),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(),
                  tileColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(height: 30),

                // TOMBOL KELUAR
                ElevatedButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text("Keluar", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}