import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String _currentProfileBase64 = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _currentProfileBase64 = data['profilePic'] ?? '';
        });
      }
    }
  }

  // FUNGSI MENGAMBIL FOTO & UBAH KE BASE64
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20, maxWidth: 400);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _currentProfileBase64 = base64Encode(bytes);
      });
    }
  }

  // FUNGSI SIMPAN KE DATABASE
  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'username': _usernameController.text.trim(),
          'profilePic': _currentProfileBase64,
        });
        if (mounted) {
          Navigator.pop(context); // Kembali ke profil setelah sukses
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diperbarui!")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil", style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.withOpacity(0.3), // Background dinamis transparan
                  backgroundImage: _currentProfileBase64.isNotEmpty
                      ? MemoryImage(base64Decode(_currentProfileBase64)) as ImageProvider
                      : const NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary, // Warna tombol dinamis
                      shape: BoxShape.circle
                    ),
                    child: const Icon(Icons.camera_alt, size: 20),
                  ),
                )
              ],
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color), // Warna inputan dinamis
              decoration: InputDecoration(
                labelText: "Username Baru",
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                prefixIcon: Icon(Icons.person, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _isLoading
                ? CircularProgressIndicator(color: Theme.of(context).colorScheme.primary) // Warna loading dinamis
                : ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary, // Warna tombol dinamis
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("SIMPAN PERUBAHAN", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
  }
}