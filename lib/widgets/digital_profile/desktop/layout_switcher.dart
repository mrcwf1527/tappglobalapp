// lib/widgets/digital_profile/desktop/layout_switcher.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/digital_profile_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../models/social_platform.dart';

class LayoutSwitcher extends StatelessWidget {
  const LayoutSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Layout:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildLayoutPreview(
                      context,
                      'Classic',
                      ProfileLayout.classic,
                      provider,
                    ),
                    const SizedBox(width: 16),
                    _buildLayoutPreview(
                      context,
                      'Portrait',
                      ProfileLayout.portrait,
                      provider,
                    ),
                    const SizedBox(width: 16),
                    _buildLayoutPreview(
                      context,
                      'Banner',
                      ProfileLayout.banner,
                      provider,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayoutPreview(
    BuildContext context,
    String text,
    ProfileLayout layout,
    DigitalProfileProvider provider,
  ) {
    final isSelected = provider.selectedLayout == layout;

    return Expanded(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect( // Added ClipRRect
                borderRadius: BorderRadius.circular(8), // Match container's borderRadius
                  child: _buildPreviewContent(layout, provider),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(text),
          Radio<ProfileLayout>(
            value: layout,
            groupValue: provider.selectedLayout,
            onChanged: (value) {
              if (value != null) {
                provider.setLayout(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(
      ProfileLayout layout, DigitalProfileProvider provider) {
    final data = provider.profileData.toMap();

    switch (layout) {
      case ProfileLayout.classic:
        return Container(
          color: const Color(0xFF0E0E0E),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: data['profileImageUrl'] != null
                          ? NetworkImage(data['profileImageUrl'])
                          : null,
                      child: data['profileImageUrl'] == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                  ),
                  if (data['companyImageUrl'] != null)
                    Positioned(
                      bottom: -6,
                      right: -12,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(data['companyImageUrl']),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                data['displayName'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${data['jobTitle'] ?? ''} at ${data['companyName'] ?? ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                textAlign: TextAlign.center,
              ),
               if (data['location'] != null)
                Padding(
                  padding: const EdgeInsets.only(top:4),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        data['location'],
                        style: const TextStyle(color: Colors.white70,fontSize: 10),
                      ),
                    ],
                  ),
                ),
                 if (data['bio'] != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data['bio'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 6),
              if (data['socialPlatforms'] != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 8),
                   child: _buildSocialIcons(data['socialPlatforms'] ?? []),
                 ),
            ],
          ),
        );

      case ProfileLayout.portrait:
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFF0E0E0E)),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    height: 250,
                    child: data['profileImageUrl'] != null
                        ? Image.network(
                            data['profileImageUrl'],
                            fit: BoxFit.fitHeight,
                          )
                        : Container(color: Colors.grey[900]),
                  ),
                ),
              ),
              Positioned(
                  top: 250,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                     Text(
                      data['displayName'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${data['jobTitle'] ?? ''} at ${data['companyName'] ?? ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                     if (data['location'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top:4),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            data['location'],
                            style: const TextStyle(color: Colors.white70,fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                     if (data['bio'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data['bio'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                      const SizedBox(height: 6),
                    if (data['socialPlatforms'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildSocialIcons(data['socialPlatforms'] ?? []),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        case ProfileLayout.banner:
        return Container(
          color: const Color(0xFF0E0E0E),
          child: Stack(
            children: [
              if (data['bannerImageUrl'] != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120, // Set a fixed height for the banner image
                  child: Image.network(
                    data['bannerImageUrl'],
                    fit: BoxFit.cover,
                  ),
                ),
              Positioned(
                top: 88, // Adjusted top position of the content.
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                         Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: CircleAvatar(
                            radius: 30, // Adjusted avatar radius
                            backgroundImage: data['profileImageUrl'] != null
                                ? NetworkImage(data['profileImageUrl'])
                                : null,
                                child: data['profileImageUrl'] == null
                                ? const Icon(Icons.person, size: 30)
                                : null,
                          ),
                         ),
                        if (data['companyImageUrl'] != null)
                          Positioned(
                            bottom: 0,
                            right: -12,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: CircleAvatar(
                                radius: 12, // Adjusted company logo radius
                                backgroundImage:
                                    NetworkImage(data['companyImageUrl']),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                     Text(
                      data['displayName'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['jobTitle'] ?? ''} at ${data['companyName'] ?? ''}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 10),
                           textAlign: TextAlign.center,
                    ),
                     if (data['location'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top:4),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            data['location'],
                            style: const TextStyle(color: Colors.white70,fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                     if (data['bio'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        data['bio'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 4),
                      if (data['socialPlatforms'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildSocialIcons(data['socialPlatforms'] ?? []),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
    Widget _buildSocialIcons(List<dynamic> platforms) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
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

        return socialPlatform.imagePath != null
            ? SvgPicture.asset(
                socialPlatform.imagePath!,
                width: 15,
                height: 15,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              )
            : FaIcon(
                socialPlatform.icon ?? FontAwesomeIcons.link,
                color: Colors.white,
                size: 15,
              );
      }).toList(),
    );
  }
}