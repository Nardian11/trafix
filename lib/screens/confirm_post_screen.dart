import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'main_dashboard.dart';

class ConfirmPostScreen extends StatefulWidget {
  final File imageFile;

  const ConfirmPostScreen({super.key, required this.imageFile});

  @override
  State<ConfirmPostScreen> createState() => _ConfirmPostScreenState();
}

class _ConfirmPostScreenState extends State<ConfirmPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isUploading = false;
  bool _isFetchingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS tidak aktif. Mohon nyalakan GPS kamu.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Buka pengaturan HP.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String streetName =
            '${place.street ?? place.name}, ${place.subLocality ?? place.locality}';

        setState(() {
          _locationController.text = streetName;
        });
      }
    } catch (e) {
      setState(() {
        _locationController.text = 'Gagal melacak lokasi';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_captionController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caption dan Lokasi wajib diisi!')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User belum login");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      String username = userDoc['username'] ?? 'User';

      final bytes = await widget.imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // ==========================================================
      // SIMPAN KE FIRESTORE (DENGAN STRUKTUR ARRAY BARU)
      // ==========================================================
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': currentUser.uid,
        'name': username,
        'username': username,
        'location': _locationController.text.trim(),
        'caption': _captionController.text.trim(),
        'image': base64Image,
        'likesCount': 0, // Dipertahankan untuk kompabilitas UI lama jika ada
        'likedVoters': [], // Array baru untuk 1 User 1 Like
        'correctVoters': [], // Array baru untuk Centang
        'incorrectVoters': [], // Array baru untuk Silang
        'commentsCount': 0, // Hitungan awal komentar
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ==========================================================
      // TEMBAK API VERCEL (SMART NOTIFICATION BERDASARKAN JALAN)
      // ==========================================================
      try {
        final url = Uri.parse(
          'https://project-uas-pab2-trafix.vercel.app/send-to-topic',
        );

        // Membedah nama jalan untuk dijadikan Target Topic Vercel
        String rawLocation = _locationController.text.trim().toLowerCase();
        List<String> locationWords = rawLocation.split(RegExp(r'[\s,.]+'));

        String targetedTopic = "kemacetan"; // Default topic
        for (var word in locationWords) {
          // Cari kata unik (mengabaikan kata 'jalan', 'raya', dll)
          if (word.length > 3 &&
              word != 'jalan' &&
              word != 'gang' &&
              word != 'raya' &&
              word != 'jln') {
            targetedTopic =
                word; // Contoh: akan menjadi "sudirman" atau "demang"
            break;
          }
        }

        final body = jsonEncode({
          "topic": "kemacetan",
          "title": "🚨 Macet Baru di Jalan Pantauanmu!",
          "body": "Info dari $username di ${_locationController.text.trim()}",
          "senderName": username,
        });

        await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      } catch (e) {
        print("Gagal menembak API Vercel: $e");
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainDashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal upload: $e. Pastikan ukuran gambar kecil (< 1MB)',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirm Post',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1E2F3E)),
                  SizedBox(height: 16),
                  Text(
                    'Mengunggah laporan...',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      widget.imageFile,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Lokasi (Nama Jalan)',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: _isFetchingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1E2F3E),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                              ),
                              onPressed: _getCurrentLocation,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _captionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Keterangan Macet...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isFetchingLocation ? null : _uploadPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2F3E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'POST LAPORAN',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
