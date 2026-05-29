import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'confirm_post_screen.dart'; // Layar selanjutnya setelah foto diambil

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Fungsi untuk membuka Kamera
  Future<void> _openCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality:
          20, // KUNCI UTAMA: Kompres ekstrem agar aman di Firestore (< 1MB)
      maxWidth: 600, // KUNCI UTAMA: Batasi resolusi lebar gambar
    );

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });

      // Jika foto berhasil diambil, langsung pindah ke layar Konfirmasi
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmPostScreen(imageFile: _imageFile!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close), 
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Report',
          style: TextStyle(fontWeight: FontWeight.bold), 
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 100,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openCamera, 
              // HAPUS Colors.white dari Icon agar bisa diatur oleh foregroundColor
              icon: const Icon(Icons.camera), 
              label: const Text(
                'Buka Kamera',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary, // Background dinamis
                // KUNCI JAWABAN: Set foregroundColor agar Teks & Icon otomatis kontras!
                foregroundColor: Theme.of(context).colorScheme.onPrimary, 
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}