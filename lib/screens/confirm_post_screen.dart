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

      // INISIALISASI AWAL SKEMA ARRAY FIRESTORE
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': currentUser.uid,
        'name': username,
        'username': username,
        'location': _locationController.text.trim(),
        'caption': _captionController.text.trim(),
        'image': base64Image,
        'likesCount': 0,
        'likedVoters': [],
        'correctVoters': [],
        'incorrectVoters': [],
        'commentsCount': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ==========================================================
      // KUNCI JAWABAN: LOGIKA SPESIFIK NAMA JALAN DIKEMBALIKAN
      // ==========================================================
      try {
        final url = Uri.parse(
          'https://project-uas-pab2-trafix.vercel.app/send-to-topic',
        );

        String rawLocation = _locationController.text.trim().toLowerCase();
        List<String> locationWords = rawLocation.split(RegExp(r'[\s,.]+'));

        String targetedTopic = "umum";
        for (var word in locationWords) {
          if (word.length > 3 &&
              word != 'jalan' &&
              word != 'gang' &&
              word != 'raya' &&
              word != 'jln') {
            targetedTopic = word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
            break;
          }
        }

        // MENGAMBIL WAKTU SAAT INI (JAM:MENIT)
        DateTime now = DateTime.now();
        String timeString =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

        final body = jsonEncode({
          "topic": "jalan_$targetedTopic",
          "title": "🚨 Laporan Baru di Jalan Pantauanmu!",
          // MENYELIPKAN WAKTU KE DALAM BODY NOTIFIKASI
          "body":
              "[$timeString WIB] Info dari $username di ${_locationController.text.trim()}",
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
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirm Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mengunggah laporan...',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
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

                  // ==========================================================
                  // KOLOM LOKASI (SUDAH DIKUNCI AGAR TIDAK BISA DIEDIT MANUAL)
                  // ==========================================================
                  TextField(
                    controller: _locationController,
                    readOnly:
                        true, // <--- KUNCI JAWABAN: Memblokir ketikan manual
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Lokasi (Nama Jalan)',
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: Theme.of(
                          context,
                        ).iconTheme.color?.withOpacity(0.7),
                      ),
                      suffixIcon: _isFetchingLocation
                          ? Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.my_location,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: _getCurrentLocation,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _captionController,
                    maxLines: 3,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Keterangan Macet...',
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isFetchingLocation ? null : _uploadPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'POST LAPORAN',
                      style: TextStyle(
                        fontSize: 16,
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
