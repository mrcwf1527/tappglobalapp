// lib/screens/digital_profile/edit_digital_profile_screen.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tabs/header_tab.dart';
import '../../providers/digital_profile_provider.dart';
import '../../widgets/navigation/web_side_nav.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/digital_profile/desktop/desktop_preview.dart';
import '../../widgets/digital_profile/desktop/desktop_tabs.dart';
import '../../widgets/digital_profile/desktop/layout_switcher.dart';

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
            _buildHeaderTabContent(isMobile: true), // Pass isMobile as true
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
  final maxWidth = MediaQuery.of(context).size.width - 230.0; // Account for WebSideNav width
  final shouldCenter = maxWidth > 1530;
  final contentWidth = shouldCenter ? 1530.0 : maxWidth;

  return Consumer<DigitalProfileProvider>(
    builder: (context, provider, child) => Scaffold(
      body: Row(
        children: [
          WebSideNav(
            selectedIndex: 4, // Profile tab
            onTabSelected: (index) {
              if (index == 0) Navigator.pushReplacementNamed(context, '/home');
              if (index == 1) Navigator.pushReplacementNamed(context, '/leads');
              if (index == 2) Navigator.pushReplacementNamed(context, '/scan');
              if (index == 3) Navigator.pushReplacementNamed(context, '/inbox');
              if (index == 4) Navigator.pop(context);
              if (index == 5) Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          Expanded(
            child: Scaffold(
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
                                color: isDark ? const Color(0xFF191919) : Colors.grey[100],
                                child: TabBarView(
                                  controller: _tabController,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _buildHeaderTabContent(isMobile: false), // Pass isMobile as false
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
                            const Expanded(child: DesktopPreview()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildHeaderTabContent({required bool isMobile}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) _buildUrlTextField(), // Conditionally render on mobile
          if (isMobile) const SizedBox(height: 24),
          const LayoutSwitcher(),
          const SizedBox(height: 24),
          const HeaderTab(),
        ],
      ),
    );
  }
   Widget _buildUrlTextField() {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          TextFormField(
            controller: TextEditingController(text: provider.profileData.username),
            enabled: false,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: 'URL',
              prefixText: 'https://l.tappglobal.app/',
              prefixStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
                fontSize: 16,
              ),
               contentPadding: const EdgeInsets.only(top: 20, bottom: 10, left: 16, right: 16), //Added this line
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Username cannot be changed after creation',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}