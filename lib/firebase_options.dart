// lib/firebase_options.dart
// Manages Firebase configuration for different platforms (Web, iOS, Android), Loads environment variables for Firebase credentials, Provides platform-specific Firebase initialization options
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static final FirebaseOptions web = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_WEB'] ?? '',
    // apiKey: const String.fromEnvironment('FIREBASE_API_KEY_WEB'),
    appId: '1:756432671303:web:24bc8e4592dc32c0651762',
    messagingSenderId: '756432671303',
    projectId: 'tappglobal-app',
    authDomain: 'tappglobal-app.firebaseapp.com',
    storageBucket: 'tappglobal-app.firebasestorage.app',
  );

  static final FirebaseOptions android = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '',
    appId: '1:756432671303:android:5345f4240580058e651762',
    messagingSenderId: '756432671303',
    projectId: 'tappglobal-app',
    storageBucket: 'tappglobal-app.firebasestorage.app',
  );

  static final FirebaseOptions ios = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_IOS'] ?? '',
    appId: '1:756432671303:ios:555fc7bdfce065ce651762',
    messagingSenderId: '756432671303',
    projectId: 'tappglobal-app',
    storageBucket: 'tappglobal-app.firebasestorage.app',
    iosClientId: '756432671303-mbfigkvshcm0l1e3hkbkgukdbii8rf8k.apps.googleusercontent.com',
    iosBundleId: 'com.tappglobal.app',
  );
}