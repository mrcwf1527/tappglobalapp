// lib/screens/home_screen.dart
// Under TAPP! Global Flutter Project
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'leads_screen.dart';
import 'scan_screen.dart';
import 'digital_profile/digital_profile_screen.dart';
import 'inbox_screen.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/navigation/app_drawer.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } else {
      await _authService.createUserDocument(user);
      if (mounted) {
        setState(() => _initialized = true);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == -1) {
      _handleSignOut();
      return;
    }

    if (index == 12) {
      Navigator.pushNamed(context, '/settings');
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

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF191919)
            : const Color(0xFFF5F5F5),
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: AppDrawer(onSignOut: _handleSignOut),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  String get appBarTitle {
    return switch (_selectedIndex) {
      0 => 'TAPP!',
      1 => 'Leads',
      2 => 'Scan',
      3 => 'Inbox',
      4 => 'Digital Profile',
      _ => 'TAPP!'
    };
  }


  Widget _buildBody() {
    return KeyedSubtree(
      key: ValueKey<int>(_selectedIndex),
      child: switch (_selectedIndex) {
        0 => _buildHomeContent(),
        1 => const LeadsScreen(),
        2 => const ScanScreen(),
        3 => const InboxScreen(),
        4 => const DigitalProfileScreen(),
        _ => _buildHomeContent(),
      },
    );
  }

  Widget _buildHomeContent() {
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