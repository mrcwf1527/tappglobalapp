// lib/screens/digital_profile/public_digital_profile_screen.dart
// Profile Management: Public digital profile view
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/social_platform.dart';
import '../../../models/block.dart';

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

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _trackView();
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

          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  minHeight: MediaQuery.of(context).size.height
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildHeader(data),
                    const SizedBox(height: 24),
                    _buildMainContent(data),
                    _buildActionButtons(data),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
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
                if (data['companyImageUrl'] != null)
                  Positioned(
                    bottom: 0,
                    right: -30,
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
              if (data['companyImageUrl'] != null)
                Positioned(
                  bottom: 0,
                  right: -30,
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


  Widget _buildWebsiteBlock(Block block) {
    final alignment = block.textAlignment ?? TextAlignment.center;
  
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
          ...block.contents
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: alignment == TextAlignment.center 
                        ? Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              if (content.imageUrl != null && content.imageUrl!.isNotEmpty)
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
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      content.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (content.subtitle != null && content.subtitle!.isNotEmpty)
                                      Text(
                                        content.subtitle!,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
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
                              Column(
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
                                  ),
                                  if (content.subtitle != null && content.subtitle!.isNotEmpty)
                                    Text(
                                      content.subtitle!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
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
                          ),
                    ),
                  ),
                ),
              )),
        ],
      ),
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
      child: PageView.builder(
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

  Widget _buildMainContent(Map<String, dynamic> data) {
    final layout = data['layout'] != null 
        ? ProfileLayout.values.firstWhere(
            (e) => e.name == data['layout'],
            orElse: () => ProfileLayout.banner)
        : ProfileLayout.banner;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: layout == ProfileLayout.portrait ? 24 : 80),
          Text(
            data['displayName'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              if (data['jobTitle'] != null && data['jobTitle'].isNotEmpty) ...[
                Text(
                  data['jobTitle'],
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (data['companyName'] != null && data['companyName'].isNotEmpty) ...[
                  Text(
                    ' at ',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    data['companyName'],
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ],
            ],
          ),
          if (data['location'] != null && data['location'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  data['location'],
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (data['bio'] != null)
            Text(
              data['bio'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 24),
          _buildSocialIcons(data['socialPlatforms'] ?? []),
          const SizedBox(height: 24),
          if (data['blocks'] != null) ...[
            ...(data['blocks'] as List)
                .map((b) => Block.fromMap(b))
                .where((block) => 
                    block.type == BlockType.website && 
                    block.isVisible == true &&
                    block.layout == BlockLayout.classic)
                .map((block) => _buildWebsiteBlock(block))
            ,
             ...(data['blocks'] as List)
                .map((b) => Block.fromMap(b))
                .where((block) => block.type == BlockType.image && 
                                  block.isVisible == true)
                .map((block) => _buildImageBlock(block)),
          ],
        ],
      ),
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
}