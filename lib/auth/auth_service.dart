import 'package:firebase_auth/firebase_auth.dart';

/// Simple wrapper around [FirebaseAuth] for email/password auth.
class AuthService {
  AuthService._();

  /// Singleton instance.
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes for the current user.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in user, or `null` if signed out.
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Create a user with email and password.
  ///
  /// You can choose whether to expose this in your UI.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user.
  Future<void> signOut() => _auth.signOut();
}



