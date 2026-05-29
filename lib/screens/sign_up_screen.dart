import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 

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
  bool _isLoading = false; 

  // ========================================================
  // LOGIKA UTAMA: PENDAFTARAN FIREBASE
  // ========================================================
  Future<void> _registerUser() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!')));
      return;
    }

    setState(() {
      _isLoading = true; 
    });

    try {
      // 1. Daftarkan Email & Password ke Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      // 2. Simpan data tambahan ke Cloud Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), 
      });

      // 3. LOGIKA BENAR: Logout paksa agar tidak otomatis masuk, lalu kembali ke Sign In
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dibuat! Silakan Sign In untuk melanjutkan.')),
        );
        Navigator.pop(context); // Kembali ke halaman Sign In
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat mendaftar.';
      if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email tersebut sudah terdaftar digunakan akun lain.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email yang kamu masukkan tidak valid.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; 
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
      // backgroundColor dihapus agar dinamis
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              ) 
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tombol Back Dinamis
                    Align(
                      alignment: Alignment.topLeft,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary, // Warna navy di Light, aksen di Dark
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Sign up now',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color, // Teks otomatis hitam/putih
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please fill the details and create account',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
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
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
                          letterSpacing: 2.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Color(0xFF8D8D8D)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Color(0xFF8D8D8D)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
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
                    Text(
                      'Password must be at least 6 characters', 
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 11),
                    ),

                    const SizedBox(height: 40),

                    // Tombol Sign Up
                    ElevatedButton(
                      onPressed: _registerUser, 
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary, // Warna menyesuaikan tema
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
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
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)),
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