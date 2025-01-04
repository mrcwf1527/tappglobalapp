// lib/screens/digital_profile/edit_digital_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/digital_profile_provider.dart';
import 'tabs/header_tab.dart';

class EditDigitalProfileScreen extends StatefulWidget {
  final String profileId;
  const EditDigitalProfileScreen({
    super.key,
    required this.profileId,
  });

  @override
  State<EditDigitalProfileScreen> createState() => _EditDigitalProfileScreenState();
}

class _EditDigitalProfileScreenState extends State<EditDigitalProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Add this line
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DigitalProfileProvider>().loadProfile(widget.profileId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, child) => Scaffold(
        appBar: AppBar(
          title: const Text('Digital Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Header'),
              Tab(text: 'Blocks'),
              Tab(text: 'Insights'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const HeaderTab(),
            const Center(child: Text('Blocks')),
            const Center(child: Text('Insights')),
            const Center(child: Text('Settings')),
          ],
        ),
      ),
    );
  }
}