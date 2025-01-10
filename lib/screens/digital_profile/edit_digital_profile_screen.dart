// lib/screens/digital_profile/edit_digital_profile_screen.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  State<EditDigitalProfileScreen> createState() =>
      _EditDigitalProfileScreenState();
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
            _buildHeaderTabContent(isMobile: true),
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
    final maxWidth = MediaQuery.of(context).size.width - 230.0;
    final shouldCenter = maxWidth > 1530;
    final contentWidth = shouldCenter ? 1530.0 : maxWidth;

    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, child) => Scaffold(
        body: Row(
          children: [
            WebSideNav(
              selectedIndex: 4,
              onTabSelected: (index) {
                if (index == 0) Navigator.pushReplacementNamed(context, '/home');
                if (index == 1) Navigator.pushReplacementNamed(context, '/leads');
                if (index == 2) Navigator.pushReplacementNamed(context, '/scan');
                if (index == 3) Navigator.pushReplacementNamed(context, '/inbox');
                if (index == 5) {
                  Navigator.pushReplacementNamed(context, '/settings');
                }
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
                                  color: isDark
                                      ? const Color(0xFF191919)
                                      : Colors.grey[100],
                                  child: TabBarView(
                                    controller: _tabController,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: [
                                      _buildHeaderTabContent(isMobile: false),
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
                            children: const [
                              Expanded(child: DesktopPreview()),
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
          if (isMobile) _buildUrlTextField(),
          if (isMobile) const SizedBox(height: 24),
          const LayoutSwitcher(),
          const HeaderTab(),
        ],
      ),
    );
  }

  void _showShareModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<DigitalProfileProvider>(
        builder: (context, provider, child) => ShareProfileSheet(
          username: provider.profileData.username,
          displayName: provider.profileData.displayName ?? '',
          profileImageUrl: provider.profileData.profileImageUrl,
        ),
      ),
    );
  }

  Widget _buildUrlTextField() {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller:
                      TextEditingController(text: provider.profileData.username),
                  enabled: false,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      fontSize: 16,
                    ),
                    contentPadding: const EdgeInsets.only(
                        top: 20, bottom: 10, left: 16, right: 16),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final url = Uri.parse(
                      'https://tappglobal-app-profile.web.app/${provider.profileData.username}');
                  await launchUrl(url);
                },
                icon: FaIcon(
                  FontAwesomeIcons.upRightFromSquare,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: () async {
                  final link =
                      'https://tappglobal-app-profile.web.app/${provider.profileData.username}';
                  await Clipboard.setData(ClipboardData(text: link));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: FaIcon(
                  FontAwesomeIcons.copy,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showShareModal(); // Calling the share modal function
                },
                icon: FaIcon(
                  FontAwesomeIcons.share,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
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

class ShareProfileSheet extends StatelessWidget {
  final String username;
  final String displayName;
  final String? profileImageUrl;

  const ShareProfileSheet({
    required this.username,
    required this.displayName,
    this.profileImageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Share Profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                BorderedQRView(
                  data: 'https://tappglobal-app-profile.web.app/$username',
                  profileImageUrl: profileImageUrl,
                ),
                const SizedBox(height: 24),
                _buildOption(
                  context,
                  'Share Profile',
                  FontAwesomeIcons.shareNodes,
                  () => _shareProfile(context),
                ),
                _buildOption(
                  context,
                  'Share Card Offline',
                  FontAwesomeIcons.fileExport,
                  () => _shareOffline(context),
                ),
                _buildOption(
                  context,
                  'Add to Wallet',
                  FontAwesomeIcons.wallet,
                  () => _addToWallet(context),
                ),
                _buildOption(
                  context,
                  'Save QR Code',
                  FontAwesomeIcons.download,
                  () => _saveQR(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            FaIcon(icon, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareProfile(BuildContext context) async {
    final text =
        'Hi I\'m $displayName, here\'s my digital profile: https://tappglobal-app-profile.web.app/$username';
    await Share.share(text);
  }

  // TODO: Implement vCard sharing
  void _shareOffline(BuildContext context) {}

  // TODO: Implement wallet integration
  void _addToWallet(BuildContext context) {}

  // TODO: Implement QR saving
  void _saveQR(BuildContext context) {}
}

class BorderedQRView extends StatelessWidget {
  final String data;
  final String? profileImageUrl;
  final double size;

  const BorderedQRView({
    required this.data,
    this.profileImageUrl,
    this.size = 200,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        QrImageView(
          data: data,
          size: size,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white
              : Colors.black,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.black,
          ),
        ),
        if (profileImageUrl != null)
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                ? Color(0xFF191919)
                : Color(0xFFf5f5f5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image(
                  image: NetworkImage(profileImageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }
}