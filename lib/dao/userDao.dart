import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanged => _firebaseAuth.authStateChanges();

  Future signInEmailPassword(
      {required String email, required String password}) async {
    await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future registerWithUserPassword(
      {required String email, required String password}) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future signOut() async {
    await _firebaseAuth.signOut();
  }

  Future rememberPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
