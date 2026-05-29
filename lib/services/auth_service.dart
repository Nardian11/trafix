import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Memantau status login (apakah pengguna sudah masuk atau belum)
  Stream<User?> get userStream => _auth.authStateChanges();

  // Fungsi Pendaftaran Akun Baru (Register)
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print("Gagal Register: $e");
      return null;
    }
  }

  // Fungsi Masuk Akun (Login)
  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print("Gagal Login: $e");
      return null;
    }
  }

  // Fungsi Keluar Akun (Logout)
  Future<void> logout() async {
    await _auth.signOut();
  }
}