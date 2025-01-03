// lib/screens/digital_profile/tabs/header_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late TextEditingController _usernameController;
  
  @override
  void initState() {
    super.initState();
    final provider = context.read<DigitalProfileProvider>();
    _usernameController = TextEditingController(text: provider.profileData.username);
    
    _usernameController.addListener(() {
      provider.updateProfile(username: _usernameController.text);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

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
            const Row(
              children: [
                Expanded(child: ProfileImageUpload()),
                SizedBox(width: 16),
                Expanded(child: CompanyImageUpload()),
              ],
            ),
            const SizedBox(height: 24),
            const BannerUpload(),
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
      builder: (context, provider, child) => TextFormField(
        controller: _usernameController,
        decoration: InputDecoration(
          labelText: 'Profile Link',
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
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          LengthLimitingTextInputFormatter(50),
        ],
      ),
    );
  }
}