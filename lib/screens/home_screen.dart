// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  static final AuthService _authService = AuthService();
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Hello World'),
      ),
    );
  }
}