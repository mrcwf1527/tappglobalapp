// lib/widgets/digital_profile/desktop/profile_preview.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/social_platform.dart';
import '../../../providers/digital_profile_provider.dart';

class ProfilePreview extends StatefulWidget {
  const ProfilePreview({super.key});

  @override
  State<ProfilePreview> createState() => _ProfilePreviewState();
}

class _ProfilePreviewState extends State<ProfilePreview> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, _) {
        final data = provider.profileData.toMap(); // Changed data type casting
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 375, maxHeight: 812),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E0E),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).toInt()),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: SingleChildScrollView(
                child: Column(
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
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: 2 / 1,
          child: data['bannerImageUrl'] != null
              ? Image.network(
                  data['bannerImageUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Container(color: Colors.grey[900]),
        ),
        Positioned(
          bottom: -60,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: data['profileImageUrl'] != null
                      ? NetworkImage(data['profileImageUrl'])
                      : null,
                  child: data['profileImageUrl'] == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
              ),
              if (data['companyImageUrl'] != null)
                Positioned(
                  bottom: 0,
                  right: -30,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(data['companyImageUrl']),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 80),
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
              Text(
                '${data['jobTitle'] ?? ''} at ${data['companyName'] ?? ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (data['location'] != null) ...[
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
      case 'wechat':
      case 'qq':
      case 'kakaotalk':
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        await _copyToClipboard(value);
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${platform['id'].toString().toUpperCase()} ID copied to clipboard'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
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
              Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  minWidth: 200,
                ),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add),
                  label: const Text('Save my contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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