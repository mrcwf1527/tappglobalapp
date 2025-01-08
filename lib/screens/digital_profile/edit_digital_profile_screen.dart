// lib/screens/digital_profile/edit_digital_profile_screen.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/digital_profile_provider.dart';
import '../../widgets/responsive_layout.dart';
import 'tabs/header_tab.dart';
import '../../widgets/digital_profile/desktop/desktop_preview.dart';
import '../../widgets/digital_profile/desktop/desktop_tabs.dart';
import '../../widgets/digital_profile/desktop/layout_switcher.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return ResponsiveLayout(
      mobileLayout: _buildMobileLayout(),
      desktopLayout: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
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

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxWidth = MediaQuery.of(context).size.width;
    final shouldCenter = maxWidth > 1530;
    final contentWidth = shouldCenter ? 1530.0 : maxWidth;

    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, child) => Scaffold(
        body: Center(
          child: SizedBox(
            width: contentWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 60,
                  child: Column(
                    children: [
                      _buildDesktopHeader(),
                      Expanded(
                        child: Container(
                          color: isDark ? const Color(0xFF121212) : Colors.grey[100],
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildHeaderTabContent(),
                              const Center(child: Text('Blocks')),
                              const Center(child: Text('Insights')),
                              const Center(child: Text('Settings')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 40,
                  child: Column(
                    children: [
                      _buildPreviewHeader(),
                      const Expanded(child: DesktopPreview()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              const Text(
                'Digital Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          DesktopTabs(tabController: _tabController),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () async {
              final username = context.read<DigitalProfileProvider>().profileData.username;
              final url = Uri.parse('http://localhost:57997/$username');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Preview Digital Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LayoutSwitcher(),
          SizedBox(height: 24),
          HeaderTab(),
        ],
      ),
    );
  }
}