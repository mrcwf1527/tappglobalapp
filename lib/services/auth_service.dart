// lib/services/auth_service.dart
// Handles user authentication flows, Supports email/password, Google, Apple Sign-in, Manages user profile creation and updates
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Logger _logger = Logger();
  bool _isSigningIn = false;

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
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _logger.e('Sign up failed', error: e);
      throw FirebaseAuthException(
          code: e.code,
          message: e.code == 'email-already-in-use'
              ? 'Email address is already in use'
              : 'Sign up failed. Please try again.');
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

      throw FirebaseAuthException(code: e.code, message: message);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (_isSigningIn) {
      return null; // If already signing in, return null
    }
    _isSigningIn = true;
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider
            .addScope('https://www.googleapis.com/auth/contacts.readonly');

        // Always use popup for web
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Existing mobile implementation
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(
              code: 'cancelled', message: 'Sign in cancelled by user');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseException catch (e) {
      _logger.e('Google sign in failed with Firebase Exception: $e', error: e);
      return null;
    } catch (e) {
      _logger.e('Google sign in failed with general exception: $e', error: e);
      return null;
    } finally {
      _isSigningIn = false;
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
            code: 'cancelled', message: 'Sign in cancelled by user');
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      return userCredential;
    } catch (e) {
      _logger.e('Apple sign in failed', error: e);
      throw FirebaseAuthException(
          code: 'cancelled', message: 'Sign in cancelled by user');
    }
  }

  Future<void> createUserDocument(User user) async {
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (userDoc.exists && userDoc.data()?['profileCreated'] == true) {
      return;
    }

    try {
      String? photoURL = user.photoURL;
      if (photoURL != null && photoURL.contains('googleusercontent.com')) {
        photoURL = await _cacheGoogleProfileImage(photoURL);
      }

      await userDocRef.set({
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'profileCreated': true,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint('Permission denied creating user document: $e');
      } else {
        debugPrint('Failed to create user document: $e');
        debugPrint('Stack trace: ${e.stackTrace}');
        rethrow;
      }
    } catch (e, stack) {
      debugPrint('Failed to create user document: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  Future<String?> _cacheGoogleProfileImage(String photoURL) async {
    try {
      // Extract size parameter for Google URLs
      String finalURL = photoURL;
      if (photoURL.contains('googleusercontent.com')) {
        // Force a larger size to prevent quality issues
        finalURL = '$photoURL?sz=400';
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${_auth.currentUser?.uid}.jpg');

      final response = await http.get(Uri.parse(finalURL));
      if (response.statusCode == 200) {
        await storageRef.putData(
            response.bodyBytes, SettableMetadata(contentType: 'image/jpeg'));
        return await storageRef.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Failed to cache profile image: $e');
    }
    // Return null instead of original URL on failure
    return null;
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