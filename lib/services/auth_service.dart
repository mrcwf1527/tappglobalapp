// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Logger _logger = Logger();

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _logger.e('Password reset failed', error: e);
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
    } on FirebaseAuthException catch (e) {
      _logger.e('Sign up failed', error: e);
      throw FirebaseAuthException(
        code: e.code,
        message: e.code == 'email-already-in-use' 
          ? 'Email address is already in use'
          : 'Sign up failed. Please try again.'
      );
    }
  }

  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _logger.e('Login failed', error: e);
      String message = 'Login failed';
    
      switch (e.code) {
        case 'invalid-credential':
          message = 'Invalid email or password';
          break;
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Wrong password provided';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
      }
    
      throw FirebaseAuthException(
        code: e.code,
        message: message
      );
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'cancelled',
          message: 'Sign in cancelled by user'
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        // Add user document if it doesn't exist
        await createUserDocument(userCredential.user!);
      }
      return userCredential;

    } on FirebaseAuthException catch (e) {
      _logger.e('Google sign in failed', error: e);
      rethrow;
    } catch (e) {
      _logger.e('Google sign in failed', error: e);
      throw FirebaseAuthException(
        code: 'cancelled',
        message: 'Sign in cancelled by user'
      );
    }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (appleCredential.userIdentifier == null) {
        throw FirebaseAuthException(
          code: 'cancelled',
          message: 'Sign in cancelled by user'
        );
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
    
      if (userCredential.user != null) {
        await createUserDocument(userCredential.user!);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    
      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      _logger.e('Apple sign in failed', error: e);
      throw FirebaseAuthException(
        code: 'cancelled',
        message: 'Sign in cancelled by user'
      );
    } on FirebaseAuthException catch (e) {
      _logger.e('Apple sign in failed', error: e);
      rethrow;
    } catch (e) {
      _logger.e('Apple sign in failed', error: e);
      throw FirebaseAuthException(
        code: 'cancelled',
        message: 'Sign in cancelled by user'
      );
    }
  }

  Future<void> createUserDocument(User user) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    _logger.e('Failed to create user document', error: e);
    rethrow;
  }
}

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      _logger.e('Sign out failed', error: e);
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}