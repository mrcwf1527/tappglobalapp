// lib/screens/digital_profile/public_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tappglobalapp/widgets/responsive_layout.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

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
    final usernameDoc = await FirebaseFirestore.instance
        .collection('usernames')
        .doc(widget.username)
        .get();
    
    if (!usernameDoc.exists) return;

    final profileId = usernameDoc.get('profileId');
    final viewsRef = FirebaseFirestore.instance
        .collection('profileViews')
        .doc(profileId);

    
    Map<String, dynamic> historyEntry = {
        'timestamp': FieldValue.serverTimestamp(),
        'ip': '000',
    };
    if (kIsWeb) {
      historyEntry['referrer'] = html.window.location.href;
    }
    
      await viewsRef.update({
      'views': FieldValue.increment(1),
      'lastViewed': FieldValue.serverTimestamp(),
      'viewHistory': FieldValue.arrayUnion([historyEntry]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: _buildMobileLayout(),
      desktopLayout: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
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
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(data),
                const SizedBox(height: 24),
                _buildMainContent(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Banner Image
        if (data['bannerImageUrl'] != null)
          Image.network(
            data['bannerImageUrl'],
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        
        // Profile Image
        Positioned(
          top: 100,
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
        
        // Company Logo
        if (data['companyImageUrl'] != null)
          Positioned(
            top: 160,
            right: 140,
            child: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(data['companyImageUrl']),
              backgroundColor: Colors.white,
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
          Text(
            data['displayName'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${data['jobTitle'] ?? ''} at ${data['companyName'] ?? ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (data['location'] != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  data['location'],
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
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
          _buildActionButtons(data),
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
        final IconData icon = _getIconForPlatform(platform['id']);
        return InkWell(
          onTap: () => _launchSocialLink(platform),
          child: FaIcon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForPlatform(String platformId) {
    switch (platformId) {
      case 'facebook':
        return FontAwesomeIcons.facebook;
      case 'linkedin':
        return FontAwesomeIcons.linkedin;
      case 'twitter':
        return FontAwesomeIcons.twitter;
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'whatsapp':
        return FontAwesomeIcons.whatsapp;
      case 'phone':
        return FontAwesomeIcons.phone;
      case 'email':
        return FontAwesomeIcons.envelope;
      default:
        return FontAwesomeIcons.link;
    }
  }

  Future<void> _launchSocialLink(Map<String, dynamic> platform) async {
    String url = '';
    
    switch (platform['id']) {
      case 'phone':
        url = 'tel:${platform['value']}';
        break;
      case 'email':
        url = 'mailto:${platform['value']}';
        break;
      case 'whatsapp':
        url = 'https://wa.me/${platform['value']}';
        break;
      default:
        url = platform['value'].startsWith('http') 
            ? platform['value'] 
            : 'https://${platform['value']}';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildActionButtons(Map<String, dynamic> data) {
    return Column(
      children: [
        ElevatedButton.icon(
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
        const SizedBox(height: 16),
        if (data['phone'] != null)
          OutlinedButton.icon(
            onPressed: () => _launchSocialLink({'id': 'phone', 'value': data['phone']}),
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
            onPressed: () => _launchSocialLink({'id': 'email', 'value': data['email']}),
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
    );
  }
}