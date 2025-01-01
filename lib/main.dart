// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this import
import 'config/theme.dart';
import 'config/routes.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");  // Add this line
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('Firebase initialized successfully');

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      debugPrint('Auth State: ${user != null ? 'Logged In' : 'Logged Out'}');
    });

  } catch (e, stack) {
    debugPrint('Firebase failed: $e\n$stack');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAPP',
      theme: AppTheme.lightTheme,
      initialRoute: FirebaseAuth.instance.currentUser != null ? AppRoutes.home : AppRoutes.auth,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}