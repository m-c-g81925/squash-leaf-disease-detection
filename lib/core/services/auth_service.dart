import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  static bool get isLoggedIn => currentUser != null;

  static Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final String cleanEmail = email.trim().toLowerCase();
    final String cleanName = fullName.trim();
    final String cleanRole = role.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw const AuthServiceException(
        'Please enter the user’s full name.',
      );
    }

    if (cleanEmail.isEmpty) {
      throw const AuthServiceException(
        'Please enter an email address.',
      );
    }

    if (password.length < 6) {
      throw const AuthServiceException(
        'The password must contain at least 6 characters.',
      );
    }

    if (cleanRole != 'farmer' &&
        cleanRole != 'agriculturist') {
      throw const AuthServiceException(
        'The selected user role is invalid.',
      );
    }

    UserCredential? credential;

    try {
      credential =
          await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw const AuthServiceException(
          'The account was created, but the user information is unavailable.',
        );
      }

      await user.updateDisplayName(cleanName);

      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'fullName': cleanName,
        'email': cleanEmail,
        'role': cleanRole,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _authenticationMessage(error),
      );
    } on FirebaseException catch (error) {
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {}
      }

      throw AuthServiceException(
        error.message ??
            'Unable to save the account information.',
      );
    }
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || password.isEmpty) {
      throw const AuthServiceException(
        'Please enter your email and password.',
      );
    }

    try {
      return await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _authenticationMessage(error),
      );
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> sendPasswordResetEmail(
    String email,
  ) async {
    final String cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw const AuthServiceException(
        'Please enter your email address.',
      );
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: cleanEmail,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _authenticationMessage(error),
      );
    }
  }

  static Future<Map<String, dynamic>?>
      getCurrentUserData() async {
    final User? user = currentUser;

    if (user == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        document = await _firestore
            .collection(_usersCollection)
            .doc(user.uid)
            .get();

    return document.data();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>>
      currentUserDataStream() {
    final User? user = currentUser;

    if (user == null) {
      throw const AuthServiceException(
        'No authenticated user was found.',
      );
    }

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .snapshots();
  }

  static Future<String?> getCurrentUserRole() async {
    final Map<String, dynamic>? data =
        await getCurrentUserData();

    return data?['role']?.toString().toLowerCase();
  }

  static String _authenticationMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts were made. Please try again later.';
      case 'network-request-failed':
        return 'A network error occurred. Check your internet connection.';
      case 'operation-not-allowed':
        return 'Email and password authentication is not enabled.';
      default:
        return error.message ??
            'Authentication failed. Please try again.';
    }
  }
}

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
