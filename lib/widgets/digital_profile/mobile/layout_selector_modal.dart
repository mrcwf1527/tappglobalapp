// lib/widgets/digital_profile/mobile/layout_selector_modal.dart
// Mobile interface for selecting profile layouts, Shows profile layout previews in a modal, Handles layout selection and updates
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../models/social_platform.dart';
import '../../../providers/digital_profile_provider.dart';

class LayoutSelectorModal extends StatefulWidget {
  final ProfileLayout currentLayout;
  final Function(ProfileLayout) onLayoutSelected;

  const LayoutSelectorModal({
    super.key,
    required this.currentLayout,
    required this.onLayoutSelected,
  });

  static show(BuildContext context, ProfileLayout currentLayout,
      Function(ProfileLayout) onLayoutSelected) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: LayoutSelectorModal(
          currentLayout: currentLayout,
          onLayoutSelected: onLayoutSelected,
        ),
      ),
    );
  }

  @override
  State<LayoutSelectorModal> createState() => _LayoutSelectorModalState();
}

class _LayoutSelectorModalState extends State<LayoutSelectorModal> {
  late PageController _pageController;
  late int _currentPage;
  final List<ProfileLayout> _layouts = ProfileLayout.values;

  @override
  void initState() {
    super.initState();
    _currentPage = _layouts.indexOf(widget.currentLayout);
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildCarousel()),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Select Layout',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemCount: _layouts.length,
      itemBuilder: (context, index) {
        final isCurrentPage = index == _currentPage;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isCurrentPage ? 1.0 : 0.5,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: isCurrentPage ? 1.0 : 0.9,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _LayoutPreview(
                layout: _layouts[index],
                isSelected: widget.currentLayout == _layouts[index],
                onSelected: widget.onLayoutSelected,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
              ),
              const SizedBox(width: 16),
              ...List.generate(
                _layouts.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).primaryColor
                            : const Color(0xFFD4D4D4)
                        : Theme.of(context).brightness == Brightness.light
                            ? Colors.grey
                            : Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _layouts.length - 1
                    ? () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : const Color(0xFFD4D4D4),
              foregroundColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.white
                  : Colors.black,
            ),
            onPressed: () {
              final provider = context.read<DigitalProfileProvider>();
              final newLayout = _layouts[_currentPage];

              // Update both the selected layout and profile layout
              provider.setLayout(newLayout);
              provider.updateProfile(layout: newLayout);
              provider.saveProfile();

              widget.onLayoutSelected(newLayout);
              Navigator.of(context).pop();
            },
            child: const Text('Select Layout'),
          ),
        ],
      ),
    );
  }
}

class _LayoutPreview extends StatelessWidget {
  final ProfileLayout layout;
  final bool isSelected;
  final Function(ProfileLayout) onSelected;

  const _LayoutPreview({
    required this.layout,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      width: screenWidth * 0.6,
      child: AspectRatio(
        aspectRatio: 9 / 19,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildPreviewContent(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  layout.name.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, child) {
        final data = provider.profileData.toMap();

        switch (layout) {
          case ProfileLayout.classic:
            return SizedBox(
              width: 180,
              child: AspectRatio(
                aspectRatio: 9 / 19,
                child: Container(
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
                              backgroundImage:
                                  data['profileImageUrl'] != null &&
                                          data['profileImageUrl'].isNotEmpty
                                      ? NetworkImage(data['profileImageUrl'])
                                      : AssetImage(
                                              'assets/images/empty_profile_image.png')
                                          as ImageProvider,
                              backgroundColor: Colors.white,
                            ),
                          ),
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
                                backgroundImage:
                                    data['companyImageUrl'] != null &&
                                            data['companyImageUrl'].isNotEmpty
                                        ? NetworkImage(data['companyImageUrl'])
                                        : AssetImage(
                                                'assets/images/empty_company_image.png')
                                            as ImageProvider,
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
                        '${data['jobTitle'] != null && data['jobTitle'].isNotEmpty ? data['jobTitle'] : ''}${(data['jobTitle'] != null && data['jobTitle'].isNotEmpty && data['companyName'] != null && data['companyName'].isNotEmpty) ? ' at ' : ''}${data['companyName'] != null && data['companyName'].isNotEmpty ? data['companyName'] : ''}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                      if (data['location'] != null && data['location'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white70, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                data['location'],
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10),
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
              ),
            );

          case ProfileLayout.portrait:
            return SizedBox(
              width: 180,
              child: AspectRatio(
                aspectRatio: 9 / 19,
                child: Container(
                  color: const Color(0xFF0E0E0E),
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 180,
                          maxHeight: 250,
                        ),
                        child: data['profileImageUrl'] != null &&
                                data['profileImageUrl'].isNotEmpty
                            ? Image.network(
                                data['profileImageUrl'],
                                fit: BoxFit.contain,
                              )
                            : Image.asset(
                                'assets/images/empty_profile_image.png',
                                fit: BoxFit.contain,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                              '${data['jobTitle'] != null && data['jobTitle'].isNotEmpty ? data['jobTitle'] : ''}${(data['jobTitle'] != null && data['jobTitle'].isNotEmpty && data['companyName'] != null && data['companyName'].isNotEmpty) ? ' at ' : ''}${data['companyName'] != null && data['companyName'].isNotEmpty ? data['companyName'] : ''}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                            if (data['location'] != null &&
                                data['location'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.white70, size: 10),
                                    const SizedBox(width: 2),
                                    Text(
                                      data['location'],
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 10),
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
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 10),
                                ),
                              ),
                            const SizedBox(height: 6),
                            if (data['socialPlatforms'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _buildSocialIcons(
                                    data['socialPlatforms'] ?? []),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

          case ProfileLayout.banner:
            return SizedBox(
              width: 180,
              child: AspectRatio(
                aspectRatio: 9 / 19,
                child: Container(
                  color: const Color(0xFF0E0E0E),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: data['bannerImageUrl'] != null &&
                                data['bannerImageUrl'].isNotEmpty
                            ? Image.network(
                                data['bannerImageUrl'],
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/empty_banner_image.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 88,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border:
                                          Border.all(color: Colors.white, width: 1),
                                    ),
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundImage:
                                          data['profileImageUrl'] != null &&
                                                  data['profileImageUrl']
                                                      .isNotEmpty
                                              ? NetworkImage(
                                                  data['profileImageUrl'])
                                              : AssetImage(
                                                      'assets/images/empty_profile_image.png')
                                                  as ImageProvider,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: -12,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 1),
                                      ),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundImage:
                                            data['companyImageUrl'] != null &&
                                                    data['companyImageUrl']
                                                        .isNotEmpty
                                                ? NetworkImage(
                                                    data['companyImageUrl'])
                                                : AssetImage(
                                                        'assets/images/empty_company_image.png')
                                                    as ImageProvider,
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
                                '${data['jobTitle'] != null && data['jobTitle'].isNotEmpty ? data['jobTitle'] : ''}${(data['jobTitle'] != null && data['jobTitle'].isNotEmpty && data['companyName'] != null && data['companyName'].isNotEmpty) ? ' at ' : ''}${data['companyName'] != null && data['companyName'].isNotEmpty ? data['companyName'] : ''}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                              if (data['location'] != null &&
                                  data['location'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.white70, size: 10),
                                      const SizedBox(width: 2),
                                      Text(
                                        data['location'],
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 10),
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
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 10),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              if (data['socialPlatforms'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: _buildSocialIcons(
                                      data['socialPlatforms'] ?? []),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
        }
      },
    );
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