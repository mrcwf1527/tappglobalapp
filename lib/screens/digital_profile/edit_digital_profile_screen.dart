// lib/screens/digital_profile/edit_digital_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/digital_profile_provider.dart';
import 'tabs/header_tab.dart';

class EditDigitalProfileScreen extends StatefulWidget {
  const EditDigitalProfileScreen({super.key});

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DigitalProfileProvider(),
      child: Consumer<DigitalProfileProvider>(
        builder: (context, provider, child) => Scaffold(
          appBar: AppBar(
            title: const Text('Digital Profile'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (provider.isDirty) {
                  _showDiscardDialog(context);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            actions: [
              if (provider.isDirty)
                TextButton(
                  onPressed: () => _saveProfile(context),
                  child: const Text('Save'),
                ),
            ],
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
      ),
    );
  }

  Future<void> _saveProfile(BuildContext context) async {
    final provider = context.read<DigitalProfileProvider>();
    try {
      await provider.saveProfile();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  Future<void> _showDiscardDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}