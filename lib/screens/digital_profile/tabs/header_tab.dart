// lib/screens/digital_profile/tabs/header_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/digital_profile_provider.dart';
import '../../../widgets/digital_profile/banner_upload.dart';
import '../../../widgets/digital_profile/company_image_upload.dart';
import '../../../widgets/digital_profile/profile_form.dart';
import '../../../widgets/digital_profile/profile_image_upload.dart';
import '../../../widgets/digital_profile/social_icons.dart';

class HeaderTab extends StatefulWidget {
  const HeaderTab({super.key});

  @override
  State<HeaderTab> createState() => _HeaderTabState();
}

class _HeaderTabState extends State<HeaderTab> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildUrlTextField(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ProfileImageUpload(
                    currentImageUrl:
                        context.watch<DigitalProfileProvider>().profileData.profileImageUrl,
                    onImageUploaded: (url) {
                      context.read<DigitalProfileProvider>().updateProfile(
                            profileImageUrl: url,
                          );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CompanyImageUpload(
                    currentImageUrl:
                        context.watch<DigitalProfileProvider>().profileData.companyImageUrl,
                    onImageUploaded: (url) {
                      context.read<DigitalProfileProvider>().updateProfile(
                            companyImageUrl: url,
                          );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            BannerUpload(
              currentImageUrl:
                  context.watch<DigitalProfileProvider>().profileData.bannerImageUrl,
              onImageUploaded: (url) {
                context.read<DigitalProfileProvider>().updateProfile(
                      bannerImageUrl: url,
                    );
              },
            ),
            const SizedBox(height: 24),
            const ProfileForm(),
            const SizedBox(height: 24),
            const SocialIcons(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlTextField() {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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