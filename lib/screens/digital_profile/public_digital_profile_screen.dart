// lib/screens/digital_profile/public_digital_profile_screen.dart
// Profile Management: Public digital profile view
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../models/social_platform.dart';
import '../../../models/block.dart';
import '../../providers/digital_profile_provider.dart';
import 'package:collection/collection.dart';

enum ProfileLayout {
  classic,
  portrait,
  banner
}

class PublicProfileScreen extends StatefulWidget {
  final String username;
  const PublicProfileScreen({super.key, required this.username});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<DocumentSnapshot> _profileFuture;
  PageController? _pageController;
  double _dragStartX = 0;
  int _currentPage = 0;
  int _currentVideoPage = 0;
  PageController? _videoPageController;
  YoutubeCarouselManager? _youtubeManager;
  PageController? _websitePageController;

  @override
  void initState() {
    super.initState();
    _websitePageController = PageController();
    _pageController = PageController();
    _videoPageController = PageController();
    _profileFuture = _loadProfile();
    _trackView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfileData();
  }

  void _loadProfileData() {
    _profileFuture.then((doc) {
      if (doc.exists && mounted) {
        Provider.of<DigitalProfileProvider>(context, listen: false)
          .loadProfile(doc.id);
      }
    });
  }

  double _getVideoAspectRatio(String url) {
    return url.contains('shorts/') ? 9/16 : 16/9;
  }

  Future<DocumentSnapshot> _loadProfile() async {
    final usernameDoc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(widget.username)
        .get();

    if (!usernameDoc.exists) {
      throw Exception('Profile not found');
    }

    return FirebaseFirestore.instance
        .collection('digitalProfiles')
        .doc(usernameDoc.get('profileId'))
        .get();
  }

  Future<void> _trackView() async {
    try {
      final usernameDoc = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(widget.username)
          .get();

      if (!usernameDoc.exists) {
        debugPrint('Username document does not exist for ${widget.username}');
        return;
      }

      final profileId = usernameDoc.get('profileId');
      debugPrint('Profile ID: $profileId');

      final historyRef = FirebaseFirestore.instance
          .collection('profileViewHistory')
          .doc();

      Map<String, dynamic> historyEntry = {
        'timestamp': FieldValue.serverTimestamp(),
        'ip': '000',
      };
      if (kIsWeb) {
        historyEntry['referrer'] = html.window.location.href;
      }

      await historyRef.set({
        'profileId': profileId,
        ...historyEntry
      });


      final viewsRef = FirebaseFirestore.instance
          .collection('profileViews')
          .doc(profileId);

      final docSnapshot = await viewsRef.get();
      if (!docSnapshot.exists) {
        await viewsRef.set({
          'views': 1,
          'lastViewed': FieldValue.serverTimestamp(),
        });
        debugPrint('Profile view tracked successfully for profileId: $profileId and document was created');
      } else {
        await viewsRef.update({
          'views': FieldValue.increment(1),
          'lastViewed': FieldValue.serverTimestamp(),
        });
        debugPrint('Profile view tracked successfully for profileId: $profileId and document was updated');
      }
    } catch (e) {
      debugPrint('Error tracking profile view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<DocumentSnapshot>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final contactBlocks = data['blocks'] != null 
              ? (data['blocks'] as List)
                  .map((b) => Block.fromMap(b))
                  .where((block) => 
                    block.type == BlockType.contact && 
                    block.isVisible == true &&
                    block.layout == BlockLayout.iconButton)
                  .toList()
              : [];

          return LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: constraints.maxHeight, // Force SingleChildScrollView to occupy the whole viewport
                      child: SingleChildScrollView(
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth: 500,
                                minHeight: constraints.maxHeight, // Ensure content takes at least screen height
                            ),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E0E0E),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(26),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _buildHeader(data),
                                    const SizedBox(height: 24),
                                    _buildMainContent(data),
                                    _buildActionButtons(data),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                                if (contactBlocks.isNotEmpty)
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Material(
                                      color: Colors.transparent,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        onTap: () => _downloadVCard(contactBlocks.first),
                                        customBorder: const CircleBorder(),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF2A2A2A),
                                          ),
                                          child: const FaIcon(
                                            FontAwesomeIcons.userPlus,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ),
                  ),
              ],
            );
          }
        );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final layout = data['layout'] != null 
        ? ProfileLayout.values.firstWhere(
            (e) => e.name == data['layout'],
            orElse: () => ProfileLayout.banner)
        : ProfileLayout.banner;

    switch (layout) {
      case ProfileLayout.classic:
        return _buildClassicHeader(data);
      case ProfileLayout.portrait:
        return _buildPortraitHeader(data);
      case ProfileLayout.banner:
        return _buildBannerHeader(data);
    }
  }

  Widget _buildClassicHeader(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const SizedBox(height: 120),
          Positioned(
            bottom: -60,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _buildProfileImage(data, 60),
                if (data['companyImageUrl'] != null && data['companyImageUrl'].isNotEmpty)
                  Positioned(
                    bottom: 0,
                    right: -28,
                    child: _buildCompanyImage(data, 28),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitHeader(Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      height: 500,
      child: data['profileImageUrl'] != null && data['profileImageUrl'].isNotEmpty
          ? Image.network(
              data['profileImageUrl'],
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            )
          : Image.asset(
              'assets/images/empty_profile_image.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildBannerHeader(Map<String, dynamic> data) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: 2 / 1,
          child: data['bannerImageUrl'] != null && data['bannerImageUrl'].isNotEmpty
              ? Image.network(
                  data['bannerImageUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/empty_banner_image.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          bottom: -60,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _buildProfileImage(data, 60),
              if (data['companyImageUrl'] != null && data['companyImageUrl'].isNotEmpty)
                Positioned(
                  bottom: 0,
                  right: -28,
                  child: _buildCompanyImage(data, 28),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Add helper methods for profile and company images
  Widget _buildProfileImage(Map<String, dynamic> data, double radius) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundImage: data['profileImageUrl'] != null && data['profileImageUrl'].isNotEmpty
            ? NetworkImage(data['profileImageUrl'])
            : AssetImage('assets/images/empty_profile_image.png') as ImageProvider,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCompanyImage(Map<String, dynamic> data, double radius) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundImage: data['companyImageUrl'] != null && data['companyImageUrl'].isNotEmpty
            ? NetworkImage(data['companyImageUrl'])
            : AssetImage('assets/images/empty_company_image.png') as ImageProvider,
        backgroundColor: Colors.white,
      ),
    );
  }

  String _generateVCard(Block block) {
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
    ];
  
    return vCard.join('\n');
  }

  Widget _buildWebsiteBlock(Block block) {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, _) {
        // EXPOSED VIEW
        if (!(block.isCollapsed ?? false)) {
          return Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (block.title != null && block.title!.isNotEmpty) ...[
                  Text(
                    block.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
                if (block.description != null && block.description!.isNotEmpty) ...[
                  Text(
                    block.description!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                block.layout == BlockLayout.carousel
                  ? _buildCarouselWebsiteLayout(block)
                  : _buildClassicWebsiteLayout(block),
              ],
            ),
          );
        }

        // COLLAPSED VIEW
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Dropdown header
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => block.isCollapsed = !block.isCollapsed!),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            // Add Padding widget to create space for the icon
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),  // Add horizontal padding
                              child: Center(
                                child: Column(
                                  children: [
                                    if (block.title != null)
                                      Text(
                                        block.title!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (block.description != null)
                                      Text(
                                        block.description!,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Icon(
                                  block.isCollapsed! ? Icons.expand_more : Icons.expand_less,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ),
                  ),

                  // Dropdown content
                  if (!block.isCollapsed!)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: block.contents
                          .where((content) => content.isVisible && content.url.isNotEmpty)
                          .map((content) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _launchSocialLink({'id': 'website', 'value': content.url}, context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 64,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      if (content.imageUrl != null && content.imageUrl!.isNotEmpty) ...[
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: NetworkImage(content.imageUrl!),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              content.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                            if (content.subtitle?.isNotEmpty == true)
                                              Text(
                                                content.subtitle!,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (content.imageUrl != null && content.imageUrl!.isNotEmpty)
                                        const SizedBox(width: 40),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )).toList(),
                      ),
                    ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildCarouselWebsiteLayout(Block block) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth > 500 ? 500.0 : screenWidth;
    final imageSize = 198.0;

    final visibleContents = block.contents
        .where((content) => 
            content.isVisible && 
            content.url.isNotEmpty &&
            content.title.isNotEmpty
        ).toList();

    return SizedBox(
      width: containerWidth,
      child: visibleContents.isEmpty 
        ? const Center(child: Text('No content available', style: TextStyle(color: Colors.white70)))
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: visibleContents.map((content) {
                      return Container(
                        width: imageSize,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _launchSocialLink({'id': 'website', 'value': content.url}, context),
                            borderRadius: BorderRadius.circular(12),
                            child: Card(
                              color: const Color(0xFF2A2A2A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: content.imageUrl != null && content.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            content.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(color: Colors.black),
                                          )
                                        : Container(color: Colors.black),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            content.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (content.subtitle != null && content.subtitle!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              content.subtitle!,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildClassicWebsiteLayout(Block block) {
    final alignment = block.textAlignment ?? TextAlignment.center;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: block.contents
        .where((content) => 
            content.isVisible && 
            content.url.isNotEmpty)
        .map((content) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchSocialLink({'id': 'website', 'value': content.url}, context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildWebsiteContent(content, alignment),
                  ),
                ),
              ),
            )).toList(),
    );
  }

  Widget _buildWebsiteContent(BlockContent content, TextAlignment alignment) {
    if (alignment == TextAlignment.center) {
      return Stack(
        children: [
          if (content.imageUrl != null && content.imageUrl!.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(content.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              if (content.imageUrl != null && content.imageUrl!.isNotEmpty)
                const SizedBox(width: 52),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (content.subtitle != null && content.subtitle!.isNotEmpty) ...[
                      Text(
                        content.subtitle!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              if (content.imageUrl != null && content.imageUrl!.isNotEmpty)
                const SizedBox(width: 40),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: alignment == TextAlignment.left 
        ? MainAxisAlignment.start 
        : MainAxisAlignment.end,
      children: [
        if (alignment == TextAlignment.left && content.imageUrl != null && content.imageUrl!.isNotEmpty) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(content.imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: alignment == TextAlignment.left 
              ? CrossAxisAlignment.start 
              : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                content.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (content.subtitle != null && content.subtitle!.isNotEmpty)
                Text(
                  content.subtitle!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (alignment == TextAlignment.right && content.imageUrl != null && content.imageUrl!.isNotEmpty) ...[
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(content.imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildImageBlock(Block block) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (block.title != null && block.title!.isNotEmpty) ...[
            Text(
              block.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          if (block.description != null && block.description!.isNotEmpty) ...[
            Text(
              block.description!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          block.layout == BlockLayout.carousel
            ? _buildCarouselImageLayout(block)
            : _buildClassicImageLayout(block),
        ],
      ),
    );
  }

  Widget _buildClassicImageLayout(Block block) {
    return Column(
      children: block.contents
        .where((content) => content.isVisible && content.imageUrl != null && content.imageUrl!.isNotEmpty)
        .map((content) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: _parseAspectRatio(block.aspectRatio),
              child: Image.network(
                content.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
          ),
        )).toList(),
    );
  }

  Widget _buildCarouselImageLayout(Block block) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth > 500 ? 500.0 : screenWidth;
    final imageWidth = containerWidth - 48;
    final aspectRatio = _parseAspectRatio(block.aspectRatio);
    final imageHeight = imageWidth / aspectRatio;

    return SizedBox(
      height: imageHeight,
      width: containerWidth,
      child: Listener(
        onPointerDown: (details) {
          _dragStartX = details.position.dx;
        },
        onPointerMove: (details) {
          if (kIsWeb) {
            final currentX = details.position.dx;
            final difference = _dragStartX - currentX;
            
            if (difference.abs() > 10) {
              if (difference > 0 && _currentPage < block.contents.length - 1) {
                _pageController?.animateToPage(
                  _currentPage + 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else if (difference < 0 && _currentPage > 0) {
                _pageController?.animateToPage(
                  _currentPage - 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              _dragStartX = currentX;
            }
          }
        },
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemCount: block.contents.where((content) => 
            content.isVisible && content.imageUrl != null && content.imageUrl!.isNotEmpty
          ).length,
          itemBuilder: (context, index) {
            final content = block.contents
              .where((content) => 
                content.isVisible && content.imageUrl != null && content.imageUrl!.isNotEmpty
              ).toList()[index];
            
            return GestureDetector(
              onTap: () => _showImageViewer(context, content.imageUrl!),
              child: Container(
                width: imageWidth,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    content.imageUrl!,
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showImageViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _parseAspectRatio(String? aspectRatio) {
    if (aspectRatio == null) return 16/9;
  
    try {
      if (aspectRatio.contains(':')) {
        final parts = aspectRatio.split(':');
        return double.parse(parts[0]) / double.parse(parts[1]);
      }
      return double.parse(aspectRatio);
    } catch (e) {
      debugPrint('Error parsing aspect ratio: $e');
      return 16/9;
    }
  }

  Widget _buildYoutubeBlock(Block block) {
  return Container(
    margin: const EdgeInsets.only(top: 24),
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (block.title != null && block.title!.isNotEmpty) ...[
          Text(
            block.title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        if (block.description != null && block.description!.isNotEmpty) ...[
          Text(
            block.description!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
        block.layout == BlockLayout.carousel
          ? _buildCarouselYoutubeLayout(block)
          : _buildClassicYoutubeLayout(block),
      ],
    ),
  );
}

  Widget _buildClassicYoutubeLayout(Block block) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth > 500 ? 500.0 : screenWidth;
    final videoWidth = containerWidth - 48;

    final validVideos = block.contents
      .where((content) => 
        content.isVisible && 
        content.url.isNotEmpty &&
        _getYouTubeVideoId(content.url) != null
      ).toList();

    if (validVideos.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: validVideos.length,
      itemBuilder: (context, index) {
        final content = validVideos[index];
        final aspectRatio = _getVideoAspectRatio(content.url);
        final videoHeight = videoWidth / aspectRatio;
        final videoId = _getYouTubeVideoId(content.url)!;

        return Container(
          width: videoWidth,
          height: videoHeight,
          margin: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: YoutubePlayer(
              controller: YoutubePlayerController.fromVideoId(
                videoId: videoId,
                autoPlay: false,
                params: const YoutubePlayerParams(
                  showFullscreenButton: true,
                  showControls: true,
                  mute: false,
                  loop: false,
                ),
              ),
              aspectRatio: aspectRatio,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarouselYoutubeLayout(Block block) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth > 500 ? 500.0 : screenWidth;
    final videoWidth = containerWidth - 48;

    final validVideos = block.contents
      .where((content) => 
        content.isVisible && 
        content.url.isNotEmpty &&
        _getYouTubeVideoId(content.url) != null
      ).toList();

    if (validVideos.isEmpty) return const SizedBox.shrink();

    // Get aspect ratio of first video for container sizing
    final firstVideoAspectRatio = _getVideoAspectRatio(validVideos[0].url);
    final videoHeight = videoWidth / firstVideoAspectRatio;

    return SizedBox(
      width: containerWidth,
      child: Column(
        children: [
          SizedBox(
            height: videoHeight,
            width: containerWidth,
            child: PageView.builder(
              controller: _videoPageController,
              onPageChanged: (page) => setState(() => _currentVideoPage = page),
              itemCount: validVideos.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final content = validVideos[index];
                final videoId = _getYouTubeVideoId(content.url)!;
                final aspectRatio = _getVideoAspectRatio(content.url);
                
                return Container(
                  width: videoWidth,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: YoutubePlayer(
                      controller: YoutubePlayerController.fromVideoId(
                        videoId: videoId,
                        autoPlay: false,
                        params: const YoutubePlayerParams(
                          showFullscreenButton: true,
                          showControls: true,
                          mute: false,
                          loop: false,
                        ),
                      ),
                      aspectRatio: aspectRatio,
                    ),
                  ),
                );
              },
            ),
          ),
          if (validVideos.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentVideoPage > 0 
                      ? () => _videoPageController?.animateToPage(
                          _currentVideoPage - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                      : null,
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: _currentVideoPage > 0 ? Colors.white : Colors.white38,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ...List.generate(
                    validVideos.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentVideoPage == index ? Colors.white : Colors.white38,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _currentVideoPage < validVideos.length - 1
                      ? () => _videoPageController?.animateToPage(
                          _currentVideoPage + 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                      : null,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: _currentVideoPage < validVideos.length - 1
                        ? Colors.white : Colors.white38,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String? _getYouTubeVideoId(String url) {
    if (url.isEmpty) return null;
  
    RegExp regExp = RegExp(
      r'^.*(youtu.be\/|v\/|\/u\/\w\/|embed\/|watch\?v=|\&v=|shorts\/)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
  
    final match = regExp.firstMatch(url);
    final videoId = match?.group(2);
  
    return (videoId != null && videoId.length == 11) ? videoId : null;
  }

  Widget _buildContactBlock(Block block, [ProfileLayout? layout]) {
    switch (block.layout) {
      case BlockLayout.classic:
        return _buildClassicContactBlock(block);
      case BlockLayout.businessCard:
        return _buildBusinessCardContactBlock(block);
      case BlockLayout.qrCode:
        return _buildQRCodeContactBlock(block);
      default:
        return _buildClassicContactBlock(block);
    }
  }

  Widget _buildClassicContactBlock(Block block) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (block.title != null && block.title!.isNotEmpty) ...[
            Text(
              block.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          if (block.description != null && block.description!.isNotEmpty) ...[
            Text(
              block.description!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _downloadVCard(block),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned(
                      left: 8,
                      child: FaIcon(
                        FontAwesomeIcons.userPlus,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Center(
                      child: Text(
                        'Save Contact to Phone',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCardContactBlock(Block block) {
    final content = block.contents.firstOrNull;
    if (content == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (block.title != null && block.title!.isNotEmpty) ...[
            Text(
              block.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          if (block.description != null && block.description!.isNotEmpty) ...[
            Text(
              block.description!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          AspectRatio(
            aspectRatio: 16/9,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _downloadVCard(block),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      if (content.imageUrl != null)
                                        Container(
                                          width: 60,
                                          height: 60,
                                          margin: const EdgeInsets.only(right: 16),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                              image: NetworkImage(content.imageUrl!),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${content.firstName ?? ''} ${content.lastName ?? ''}'.trim(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (content.jobTitle?.isNotEmpty == true)
                                              Text(
                                                content.jobTitle!,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  if (content.companyName?.isNotEmpty == true)
                                    Text(
                                      content.companyName!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  _buildContactInfo(content),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (content.companyName?.isNotEmpty == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: FutureBuilder<String?>(
                            future: _getCompanyImageUrl(content.companyName!),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(snapshot.data!),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox(width: 0);
                            },
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
    );
  }

  Widget _buildQRCodeContactBlock(Block block) {
    final vCardData = _generateVCard(block);

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (block.title != null && block.title!.isNotEmpty) ...[
            Text(
              block.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          if (block.description != null && block.description!.isNotEmpty) ...[
            Text(
              block.description!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _downloadVCard(block),
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final qrSize = constraints.maxWidth > 400 ? 150.0 : constraints.maxWidth * 0.3;
                  
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Scan to add contact',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Use your phone camera to scan the QR code',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Container(
                          width: qrSize,
                          height: qrSize,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: PrettyQrView.data(
                            data: vCardData,
                            decoration: const PrettyQrDecoration(
                              shape: PrettyQrSmoothSymbol(
                                color: Colors.black,
                                roundFactor: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContactInfo(BlockContent content) {
    final phones = (content.metadata?['phones'] as List? ?? []);
    final emails = (content.metadata?['emails'] as List? ?? []);
  
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (phones.isNotEmpty)
          Text(
            phones.firstWhere((p) => p['isPrimary'] == true, 
              orElse: () => phones.first)['number'],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        if (emails.isNotEmpty)
          Text(
            emails.firstWhere((e) => e['isPrimary'] == true, 
              orElse: () => emails.first)['address'],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Future<String?> _getCompanyImageUrl(String companyName) async {
    try {
      final companyDoc = await FirebaseFirestore.instance
          .collection('digitalProfiles')
          .where('companyName', isEqualTo: companyName)
          .get();
    
      if (companyDoc.docs.isNotEmpty) {
        return companyDoc.docs.first.data()['companyImageUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching company image: $e');
      return null;
    }
  }

  Future<void> _downloadVCard(Block block) async {
    final vCardData = _generateVCard(block);
  
    if (kIsWeb) {
      final bytes = utf8.encode(vCardData);
      final base64 = base64Encode(bytes);
      final dataUrl = 'data:text/vcard;base64,$base64';
    
      // Get contact name for file
      final firstName = block.contents.firstOrNull?.firstName ?? '';
      final lastName = block.contents.firstOrNull?.lastName ?? '';
      final fileName = '${firstName.trim()} ${lastName.trim()}'.trim();
    
      // Create and click download link
      html.AnchorElement(href: dataUrl)
      ..setAttribute('download', '${fileName.isEmpty ? 'contact' : fileName}.vcf')
      ..click();
    } else {
      // For mobile platforms
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/contact.vcf');
      await file.writeAsString(vCardData);
      await Share.shareXFiles([XFile(file.path)], text: 'Contact Information');
    }
  }

  Widget _buildTextBlock(Block block) {
    final content = block.contents.firstOrNull;
    if (content == null) return const SizedBox.shrink();

    TextStyle style = const TextStyle(
      color: Colors.white,
      decorationColor: Colors.white, // Add this line for underline color
    );
    
    switch (content.textBlockStyle) {
      case TextBlockStyle.heading1:
        style = style.copyWith(fontSize: 24, fontWeight: FontWeight.bold);
      case TextBlockStyle.heading2:
        style = style.copyWith(fontSize: 20, fontWeight: FontWeight.bold);
      case TextBlockStyle.heading3:
        style = style.copyWith(fontSize: 18, fontWeight: FontWeight.bold);
      case TextBlockStyle.quote:
        style = style.copyWith(fontSize: 16, fontStyle: FontStyle.italic);
      default:
        style = style.copyWith(fontSize: 16);
    }

    if (content.isBold == true) style = style.copyWith(fontWeight: FontWeight.bold);
    if (content.isItalic == true) style = style.copyWith(fontStyle: FontStyle.italic);
    if (content.isUnderlined == true) {style = style.copyWith(decoration: TextDecoration.underline);}

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: Align(
        alignment: block.textAlignment == TextAlignment.left 
          ? Alignment.centerLeft 
          : block.textAlignment == TextAlignment.right 
            ? Alignment.centerRight 
            : Alignment.center,
        child: Text(
          content.title,
          style: style,
          textAlign: block.textAlignment == TextAlignment.left 
            ? TextAlign.left 
            : block.textAlignment == TextAlignment.right 
              ? TextAlign.right 
              : TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSpacerBlock(Block block) {
    final content = block.contents.firstOrNull;
    if (content == null) return const SizedBox.shrink();

    final height = content.metadata?['height'] as double? ?? 16.0;
    final style = content.metadata?['dividerStyle'] as String? ?? 'none';

    Widget divider;
    switch (style) {
      case 'thinLine':
        divider = Divider(height: height, thickness: 1, color: Colors.white);
      case 'thickLine':
        divider = Divider(height: height, thickness: 3, color: Colors.white);
      case 'dottedLine':
        divider = CustomPaint(
          size: Size.fromHeight(height),
          painter: DottedLinePainter(color: Colors.white),
        );
      case 'dashed':
        divider = CustomPaint(
          size: Size.fromHeight(height),
          painter: DashedLinePainter(color: Colors.white),
        );
      case 'doubleLines':
        divider = CustomPaint(
          size: Size.fromHeight(height),
          painter: DoubleLinePainter(color: Colors.white),
        );
      case 'ellipsis':
        divider = SizedBox(
          height: height,
          child: const Center(
            child: Text('• • •', style: TextStyle(fontSize: 24, color: Colors.white)),
          ),
        );
      default:
        divider = SizedBox(height: height);
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: divider,
    );
  }

  Widget _buildMainContent(Map<String, dynamic> data) {
    final provider = Provider.of<DigitalProfileProvider>(context, listen: true);
    final layout = data['layout'] != null 
        ? ProfileLayout.values.firstWhere(
            (e) => e.name == data['layout'],
            orElse: () => ProfileLayout.banner)
        : ProfileLayout.banner;

    final blocks = <Block>[];
    if (data['blocks'] != null) {
      final List<dynamic> blocksList = data['blocks'] as List;
      blocks.addAll(
        blocksList
          .map((b) => Block.fromMap(b))
          .where((block) => block.isVisible == true)
      );
      blocks.sort((a, b) => a.sequence.compareTo(b.sequence));
    }

    if (provider.profileData.blocks.isNotEmpty) {
      blocks.clear();
      blocks.addAll(
        provider.profileData.blocks
          .where((block) => block.isVisible == true)
      );
      blocks.sort((a, b) => a.sequence.compareTo(b.sequence));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: layout == ProfileLayout.portrait ? 24 : 80),
              if (data['displayName']?.isNotEmpty == true) ...[
                Text(
                  data['displayName']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (data['jobTitle']?.isNotEmpty == true || data['companyName']?.isNotEmpty == true) ...[
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    if (data['jobTitle']?.isNotEmpty == true)
                      Text(
                        data['jobTitle']!,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    if (data['jobTitle']?.isNotEmpty == true && data['companyName']?.isNotEmpty == true)
                      const Text(
                        ' at ',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    if (data['companyName']?.isNotEmpty == true)
                      Text(
                        data['companyName']!,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (data['location']?.isNotEmpty == true) ...[
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      data['location']!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (data['bio']?.isNotEmpty == true) ...[
                Text(
                  data['bio']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
              ],
              if ((data['socialPlatforms'] as List?)?.isNotEmpty == true) ...[
                _buildSocialIcons(data['socialPlatforms'] ?? []),
                const SizedBox(height: 24),
              ],
              ...blocks.map((block) {
                switch (block.type) {
                  case BlockType.website:
                    return _buildWebsiteBlock(block);
                  case BlockType.contact:
                    return block.layout != BlockLayout.iconButton 
                        ? _buildContactBlock(block, layout)
                        : const SizedBox.shrink();
                  case BlockType.image:
                    return _buildImageBlock(block);
                  case BlockType.youtube:
                    return _buildYoutubeBlock(block);
                  case BlockType.text:
                    return _buildTextBlock(block);
                  case BlockType.spacer:
                    return _buildSpacerBlock(block);
                }
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcons(List<dynamic> platforms) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: platforms.map<Widget>((platform) {
        final socialPlatform = SocialPlatforms.platforms.firstWhere(
          (p) => p.id == platform['id'],
          orElse: () => SocialPlatform(
            id: platform['id'],
            name: platform['name'],
            icon: FontAwesomeIcons.link,
          ),
        );

        return InkWell(
          onTap: () => _launchSocialLink(platform, context),
          child: socialPlatform.imagePath != null
              ? SvgPicture.asset(
                  socialPlatform.imagePath!,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                )
              : FaIcon(
                  socialPlatform.icon ?? FontAwesomeIcons.link,
                  color: Colors.white,
                  size: 24,
                ),
        );
      }).toList(),
    );
  }

  Future<void> _launchSocialLink(Map<String, dynamic> platform, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String url = '';
    final value = platform['value'];
    
    if (value == null || value.isEmpty) return;

    switch (platform['id']) {
      case 'phone':
        url = 'tel:$value';
        break;
      case 'sms':
        url = 'sms:$value';
        break;
      case 'email':
        url = 'mailto:$value';
        break;
      case 'website':
        url = value.startsWith('http') ? value : 'https://$value';
        break;
      case 'address':
        url = value.startsWith('http') ? value : 'https://$value';
        break;
      case 'red':
        url = value.startsWith('http') ? value : 'https://$value';
        break;
      case 'lemon8':
        url = value.startsWith('http') ? value : 'https://$value';
        break;
      case 'douyin':
        url = value.startsWith('http') ? value : 'https://$value';
        break;
      case 'whatsapp':
        final number = value.replaceAll('+', '');
        url = 'https://wa.me/$number';
        break;
      case 'telegram':
        url = 'https://t.me/$value';
        break;
      case 'line':
        if (value.contains('line.me')) {
          url = value.startsWith('http') ? value : 'https://$value';
        } else {
          await _copyToClipboard(value);
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('LINE ID copied to clipboard'))
          );
          return;
        }
        break;
      case 'wechat':
      case 'qq':
      case 'kakaotalk':
        await _copyToClipboard(value);
        if (!mounted) return; 
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${platform['id'].toString().toUpperCase()} ID copied to clipboard'))
        );
    return;
      case 'viber':
        if (kIsWeb) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          await _copyToClipboard(value);
          if (!mounted) return;
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Viber number copied to clipboard'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        } else {
          final number = value.replaceAll('+', '');
          url = 'viber://chat?number=$number';
        }
        break;
      case 'zalo':
        final number = value.replaceAll('+', '');
        url = 'https://zalo.me/$number';
        break;
      case 'facebook':
        url = 'https://$value';
        break;
      case 'instagram':
        url = 'https://instagram.com/$value';
        break;
      case 'linkedin':
        url = 'https://$value';
        break;
      case 'tiktok':
        url = 'https://tiktok.com/@$value';
        break;
      case 'threads':
        url = 'https://threads.net/@$value';
        break;
      case 'twitter':
        url = 'https://x.com/$value';
        break;
      case 'snapchat':
        url = 'https://snapchat.com/add/$value';
        break;
      case 'tumblr':
        url = 'https://tumblr.com/$value';
        break;
      case 'linkedin_company':
        url = 'https://$value';
        break;
      case 'mastodon':
        url = 'https://mastodon.social/@$value';
        break;
      case 'bluesky':
        url = 'https://$value';
        break;
      case 'pinterest':
        url = 'https://pinterest.com/$value';
        break;
      case 'appStore':
        url = 'https://$value';
        break;
      case 'github':
        url = 'https://github.com/$value';
        break;
      case 'gitlab':
        url = 'https://gitlab.com/$value';
        break;
      case 'youtube':
        url = 'https://youtube.com/@$value';
        break;
      case 'twitch':
        url = 'https://twitch.tv/$value';
        break;
      case 'discord':
        url = 'https://$value';
        break;
      case 'steam':
        url = 'https://steamcommunity.com/id/$value';
        break;
      case 'reddit':
        url = 'https://reddit.com/user/$value';
        break;
      case 'googleReviews':
        url = 'https://$value';
        break;
      case 'shopee':
        url = 'https://$value';
        break;
      case 'lazada':
        url = 'https://$value';
        break;
      case 'amazon':
        url = 'https://$value';
        break;
      case 'etsy':
        url = 'https://etsy.com/shop/$value';
        break;
      case 'behance':
        url = 'https://behance.net/$value';
        break;
      case 'dribbble':
        url = 'https://dribbble.com/$value';
        break;
      case 'googlePlay':
        url = 'https://$value';
        break;
        case 'weibo':
        url = 'https://$value';
        break;
      case 'naver':
        url = 'https://$value';
        break;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
  
  Widget _buildActionButtons(Map<String, dynamic> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              if (data['phone'] != null)
                OutlinedButton.icon(
                  onPressed: () => _launchSocialLink({'id': 'phone', 'value': data['phone']}, context),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call me'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (data['email'] != null)
                OutlinedButton.icon(
                  onPressed: () => _launchSocialLink({'id': 'email', 'value': data['email']}, context),
                  icon: const Icon(Icons.email),
                  label: const Text('Email me'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _websitePageController?.dispose();
    _pageController?.dispose();
    _videoPageController?.dispose();
    _youtubeManager?.dispose();
    super.dispose();
  }
}

class _YoutubeVideoPlayer extends StatefulWidget {
  final String videoId;
  final double width;
  
  const _YoutubeVideoPlayer({
    required this.videoId,
    required this.width,
  });

  @override
  State<_YoutubeVideoPlayer> createState() => _YoutubeVideoPlayerState();
}

class _YoutubeVideoPlayerState extends State<_YoutubeVideoPlayer> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        mute: false,
        loop: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _controller,
          key: ValueKey(widget.videoId),
        ),
      ),
    );
  }
}

class YoutubeCarouselManager {
  final List<YoutubePlayerController> controllers;
  
  YoutubeCarouselManager({required List<String> videoIds}) 
    : controllers = videoIds.map((id) => YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          showControls: true,
          mute: false,
          loop: false,
        ),
      )).toList();

  void dispose() {
    for (var controller in controllers) {
      controller.close();
    }
  }
}

class DottedLinePainter extends CustomPainter {
 final Color color;
 
 DottedLinePainter({required this.color});

 @override
 void paint(Canvas canvas, Size size) {
   final paint = Paint()
     ..color = color
     ..strokeWidth = 1;

   const spacing = 4.0;
   final centerY = size.height / 2;
   
   for (double x = 0; x < size.width; x += spacing * 2) {
     canvas.drawCircle(Offset(x, centerY), 1, paint);
   }
 }

 @override
 bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedLinePainter extends CustomPainter {
 final Color color;
 
 DashedLinePainter({required this.color});

 @override
 void paint(Canvas canvas, Size size) {
   final paint = Paint()
     ..color = color
     ..strokeWidth = 1;

   const dashWidth = 5.0;
   const dashSpace = 3.0;
   final centerY = size.height / 2;
   
   for (double x = 0; x < size.width; x += dashWidth + dashSpace) {
     canvas.drawLine(
       Offset(x, centerY),
       Offset(x + dashWidth, centerY),
       paint,
     );
   }
 }

 @override
 bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DoubleLinePainter extends CustomPainter {
 final Color color;
 
 DoubleLinePainter({required this.color});

 @override
 void paint(Canvas canvas, Size size) {
   final paint = Paint()
     ..color = color
     ..strokeWidth = 1;

   final centerY = size.height / 2;
   
   canvas.drawLine(
     Offset(0, centerY - 2),
     Offset(size.width, centerY - 2),
     paint,
   );
   
   canvas.drawLine(
     Offset(0, centerY + 2),
     Offset(size.width, centerY + 2),
     paint,
   );
 }

 @override
 bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}