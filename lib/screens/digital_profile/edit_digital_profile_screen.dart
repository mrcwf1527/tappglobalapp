// lib/screens/digital_profile/edit_digital_profile_screen.dart
// Profile Management: Digital profile editing interface
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'tabs/blocks/blocks_tab.dart';
import 'tabs/header/header_tab.dart';
import '../../utils/image_saver.dart';
import '../../models/block.dart';
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
            const BlocksTab(),
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
                  _showShareModal();
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

class ShareProfileSheet extends StatefulWidget {
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
  State<ShareProfileSheet> createState() => _ShareProfileSheetState();
}

class _ShareProfileSheetState extends State<ShareProfileSheet> {
  final _qrKey = GlobalKey<BorderedQRViewState>();
  final _vcardKey = GlobalKey();
  bool _showingVCard = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, child) {
        final hasContactBlock = provider.profileData.blocks
            .any((block) => block.type == BlockType.contact);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
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
                    if (!_showingVCard) 
                      BorderedQRView(
                        key: _qrKey,
                        data: 'https://tappglobal-app-profile.web.app/${widget.username}',
                        profileImageUrl: widget.profileImageUrl,
                      )
                    else
                      _buildVCardQR(provider),
                    const SizedBox(height: 24),
                    _buildOption(
                      context,
                      'Share Profile',
                      FontAwesomeIcons.shareNodes,
                      () => _shareProfile(context),
                    ),
                    if (hasContactBlock) _buildOption(
                      context,
                      _showingVCard ? 'Show Profile QR' : 'Share Card Offline',
                      _showingVCard ? FontAwesomeIcons.qrcode : FontAwesomeIcons.fileExport,
                      () => setState(() => _showingVCard = !_showingVCard),
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
      },
    );
  }

  Widget _buildVCardQR(DigitalProfileProvider provider) {
    final contactBlock = provider.profileData.blocks
        .firstWhere((block) => block.type == BlockType.contact);
    final vCardData = _generateVCard(provider, contactBlock);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: PrettyQrView.data(
            key: _vcardKey,
            data: vCardData,
            decoration: PrettyQrDecoration(
              shape: PrettyQrSmoothSymbol(
                color: isDarkMode ? Colors.white : Colors.black,
                roundFactor: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scan to add contact',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _generateVCard(DigitalProfileProvider provider, Block block) {
    final content = block.contents.firstOrNull;
    if (content == null) return '';

    final phones = (content.metadata?['phones'] as List? ?? []);
    final emails = (content.metadata?['emails'] as List? ?? []);

    final vCard = [
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN;CHARSET=UTF-8:${content.firstName ?? ''} ${content.lastName ?? ''}'.trim(),
      'N;CHARSET=UTF-8:${content.lastName ?? ''};${content.firstName ?? ''};;;',
      if (content.imageUrl?.isNotEmpty == true) 'PHOTO;MEDIATYPE=image/jpeg:${content.imageUrl}',
      ...emails.map((email) => 'EMAIL;CHARSET=UTF-8;type=WORK,INTERNET:${email['address']}'),
      ...phones.map((phone) => 'TEL;TYPE=CELL:${phone['number']}'),
      if (content.jobTitle?.isNotEmpty == true) 'TITLE;CHARSET=UTF-8:${content.jobTitle}',
      if (content.companyName?.isNotEmpty == true) 'ORG;CHARSET=UTF-8:${content.companyName}',
      'URL;type=TAPP! Digital Profile;CHARSET=UTF-8:https://l.tappglobal.app/${widget.username}',
      'URL;TYPE=TAPP! Calendar Link:',
      'URL;TYPE=WhatsApp:',
      'URL;TYPE=Facebook:',
      'URL;TYPE=X (Twitter):',
      'URL;TYPE=LinkedIn Personal:',
      'URL;TYPE=Instagram:',
      'URL;TYPE=Youtube Channel:',
      'URL;TYPE=TikTok:',
      'END:VCARD'
    ].join('\n');

    return vCard;
  }

  Future<Uint8List?> _exportVCardQR() async {
    debugPrint('Starting vCard QR export');
    
    // Using completer to manage async
    final completer = Completer<Uint8List?>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_vcardKey.currentContext == null) {
        debugPrint('Context is null');
        completer.complete(null);
        return;
      }

      final renderObject = _vcardKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
      if (renderObject == null) {
        debugPrint('RenderObject is null');
        completer.complete(null);
        return;
      }

      debugPrint('Generating image');
      final image = await renderObject.toImage(pixelRatio: 3.0);
      debugPrint('Converting to byte data');
      final byteData = await image.toByteData(format: ImageByteFormat.png);
     
      if (byteData == null) {
        debugPrint('ByteData is null');
         completer.complete(null);
        return;
      }

      debugPrint('Export complete');
      completer.complete(byteData.buffer.asUint8List());
    });

    return completer.future;
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
            SizedBox(
              width: 24,
              child: FaIcon(icon, size: 20),
            ),
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
        'Hi I\'m ${widget.displayName}, here\'s my digital profile: https://tappglobal-app-profile.web.app/${widget.username}';
    await Share.share(text);
  }

  // TODO: Implement Apple/Google Wallet integration
  void _addToWallet(BuildContext context) {}

  Future<void> _saveQR(BuildContext context) async {
    try {
      Uint8List? bytes;
      if (_showingVCard) {
        bytes = await _exportVCardQR();
        if (bytes == null) throw Exception('Failed to generate vCard QR');
     
        await ImageSaveUtil.saveImage(bytes, 'tapp_vcard_${widget.username}.png');
      } else {
        bytes = await _qrKey.currentState?.exportQR();
        if (bytes == null) throw Exception('Failed to generate QR');
     
        await ImageSaveUtil.saveImage(bytes, 'tapp_qr_${widget.username}.png');
      }
    
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code saved successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save QR Code')),
      );
    }
  }
}

class BorderedQRView extends StatefulWidget {
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
  State<BorderedQRView> createState() => BorderedQRViewState();
}

class BorderedQRViewState extends State<BorderedQRView> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final qrImage = QrImage(QrCode.fromData(
      data: widget.data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    ));

    final decoration = PrettyQrDecoration(
      shape: PrettyQrSmoothSymbol(
        color: isDarkMode ? Colors.white : Colors.black,
        roundFactor: 1,
      ),
      image: widget.profileImageUrl?.isNotEmpty ?? false 
        ? PrettyQrDecorationImage(
            image: NetworkImage(widget.profileImageUrl!),
            position: PrettyQrDecorationImagePosition.embedded,
          )
        : PrettyQrDecorationImage(
            image: AssetImage(isDarkMode 
              ? 'assets/logo/logo_white.png'
              : 'assets/logo/logo_black.png'),
            position: PrettyQrDecorationImagePosition.embedded,
          ),
    );

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: PrettyQrView(
        qrImage: qrImage,
        decoration: decoration,
      ),
    );
  }

  Future<Uint8List> exportQR() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final qrImage = QrImage(QrCode.fromData(
      data: widget.data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
  ));

  final decoration = PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(
      color: isDarkMode ? Colors.white : Colors.black,
      roundFactor: 1,
    ), // Remove trailing comma
    image: widget.profileImageUrl?.isNotEmpty ?? false 
      ? PrettyQrDecorationImage(
          image: NetworkImage(widget.profileImageUrl!),
          position: PrettyQrDecorationImagePosition.embedded,
        )
      : PrettyQrDecorationImage(
          image: AssetImage(isDarkMode 
            ? 'assets/logo/logo_white.png'
            : 'assets/logo/logo_black.png'),
          position: PrettyQrDecorationImagePosition.embedded,
        ),
      background: isDarkMode ? Colors.black : Colors.white
    );

    final image = await qrImage.toImage(
      size: 1024,
      decoration: decoration,
    );

    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}