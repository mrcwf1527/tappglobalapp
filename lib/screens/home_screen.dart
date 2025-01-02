// lib/screens/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/navigation/app_drawer.dart';
import '../widgets/navigation/desktop_sidebar.dart';
import '../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/auth');
          });
          return const SizedBox();
        }

        if (snapshot.data != null) {
          _authService.createUserDocument(snapshot.data!);
        }

        return ResponsiveLayout(
          mobileLayout: _buildMobileLayout(),
          desktopLayout: _buildDesktopLayout(),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    if (index == -1) {
      _handleSignOut();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  Widget _buildUserAvatar(User? user) {
    if (user?.photoURL == null) {
      return _buildDefaultAvatar();
    }

    return kIsWeb ? _buildWebAvatar(user!.photoURL!) : _buildMobileAvatar(user!);
  }

  Widget _buildWebAvatar(String url) {
    return ClipOval(
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingAvatar();
        },
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          debugPrint('Web avatar load error: $error');
          return _buildDefaultAvatar();
        },
      ),
    );
  }

  Widget _buildMobileAvatar(User user) {
    return CachedNetworkImage(
      imageUrl: user.photoURL!,
      imageBuilder: (_, imageProvider) => CircleAvatar(
        backgroundImage: imageProvider,
        backgroundColor: Colors.grey[200],
      ),
      placeholder: (_, __) => _buildLoadingAvatar(),
      errorWidget: (_, __, error) {
        debugPrint('Mobile avatar load error: $error');
        return _buildDefaultAvatar();
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      backgroundColor: Colors.grey[200],
      child: Icon(Icons.person, size: 20, color: Colors.grey[700]),
    );
  }

  Widget _buildLoadingAvatar() {
    return CircleAvatar(
      backgroundColor: Colors.grey[200],
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TAPP!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: AppDrawer(onSignOut: _handleSignOut),
      body: _buildBody(),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              DesktopSidebar(
                selectedIndex: _selectedIndex,
                onNavigate: _onItemTapped,
              ),
              if (FirebaseAuth.instance.currentUser != null)
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 72,
                        child: _buildDesktopHeader(),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildBody(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(
              maxWidth: 40,
              maxHeight: 40,
            ),
            child: _buildUserAvatar(user),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: ResponsiveLayout.isMobile(context) ? 2 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard('Total Leads', '124', Icons.people),
            _buildStatCard('Scanned Today', '8', Icons.qr_code_scanner),
            _buildStatCard('Unread Messages', '3', Icons.mail),
            _buildStatCard('Profile Views', '45', Icons.visibility),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('New Lead Added'),
            subtitle:
                Text('John Doe - ${DateTime.now().toString().split('.')[0]}'),
          ),
        ),
      ],
    );
  }
}