// lib/widgets/navigation/app_drawer.dart
// Navigation Components: Mobile side menu
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatelessWidget {
  final Function() onSignOut;

  const AppDrawer({
    super.key,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserAvatar(),
                const SizedBox(height: 10),
                Text(
                  'TAPP!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.gear),
            title: const Text('Settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.circleQuestion),
            title: const Text('Help & Support'),
            onTap: () {},
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.shield),
            title: const Text('Terms & Privacy'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const FaIcon(
              FontAwesomeIcons.rightFromBracket,
              color: Colors.red,
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.photoURL == null) {
      return _buildDefaultAvatar();
    }

    if (kIsWeb) {
      return _buildWebAvatar(user!.photoURL!);
    }
    return _buildMobileAvatar(user!);
  }

  Widget _buildWebAvatar(String url) {
    return ClipOval(
      child: Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingAvatar();
        },
        errorBuilder: (_, __, error) {
          debugPrint('Web avatar load error: $error');
          return _buildDefaultAvatar();
        },
      ),
    );
  }

  Widget _buildMobileAvatar(User user) {
    return ClipOval(
      child: Image.network(
        user.photoURL!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingAvatar();
        },
        errorBuilder: (_, __, ___) {
          debugPrint('Mobile avatar error for URL: ${user.photoURL}');
          return _buildDefaultAvatar();
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey[200],
      child: Icon(Icons.person, size: 30, color: Colors.grey[700]),
    );
  }

  Widget _buildLoadingAvatar() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey[200],
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}