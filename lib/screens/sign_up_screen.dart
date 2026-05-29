import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // IJIN MASUK: Untuk Autentikasi
import 'package:cloud_firestore/cloud_firestore.dart'; // IJIN MASUK: Untuk Simpan Data Profil
import 'main_dashboard.dart'; // Diarahkan ke Dashboard setelah sukses daftar

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false; // State untuk mendeteksi proses pendaftaran

  // ========================================================
  // LOGIKA UTAMA: PENDAFTARAN FIREBASE
  // ========================================================
  Future<void> _registerUser() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!')));
      return;
    }

    setState(() {
      _isLoading = true; // Aktifkan animasi loading
    });

    try {
      // 1. Daftarkan Email & Password ke Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Ambil ID unik (UID) pengguna yang baru dibuat
      String uid = userCredential.user!.uid;

      // 2. Simpan data tambahan (Username & HP) ke Cloud Firestore
      // Menggunakan UID dari Auth sebagai nama Dokumen agar tersinkronisasi
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // Waktu pendaftaran otomatis
      });

      // 3. Jika sukses, langsung lempar pengguna masuk ke Main Dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainDashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Menangkap error khusus dari Firebase (misal: format email salah atau password kurang dari 6 karakter)
      String errorMessage = 'Terjadi kesalahan saat mendaftar.';
      if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email tersebut sudah terdaftar digunakan akun lain.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email yang kamu masukkan tidak valid.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      // Menangkap error umum lainnya
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Matikan animasi loading setelah proses selesai
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E2F3E)),
              ) // Tampilan saat loading
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tombol Back Kotak Biru Navy
                    Align(
                      alignment: Alignment.topLeft,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2F3E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'Sign up now',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2F3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please fill the details and create account',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black45),
                    ),

                    const SizedBox(height: 40),

                    _buildInput(_usernameController, 'Enter username', false),
                    const SizedBox(height: 16),

                    _buildInput(
                      _emailController,
                      'Enter your email address',
                      false,
                      TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    _buildInput(
                      _phoneController,
                      'Enter your number',
                      false,
                      TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          letterSpacing: 2.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                            color: Color(0xFF8D8D8D),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(
                            color: Color(0xFF8D8D8D),
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.black38,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'Password must be at least 6 characters', // Catatan: Firebase Auth bawaan minimal 6 karakter
                      style: TextStyle(color: Colors.black45, fontSize: 11),
                    ),

                    const SizedBox(height: 40),

                    // Tombol Sign Up memanggil fungsi Firebase
                    ElevatedButton(
                      onPressed:
                          _registerUser, // PANGGIL MESIN REGISTRASI DI SINI
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E2F3E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              color: Color(0xFF1E2F3E),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint,
    bool isPassword, [
    TextInputType type = TextInputType.text,
  ]) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: type,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFF8D8D8D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFF8D8D8D)),
        ),
      ),
    );
  }
}
