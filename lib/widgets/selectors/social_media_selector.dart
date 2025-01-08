// lib/widgets/selectors/social_media_selector.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/social_platform.dart';
import '../responsive_layout.dart';

class SocialMediaSelector extends StatelessWidget {
  final List<String> selectedPlatformIds;

  const SocialMediaSelector({
    super.key,
    required this.selectedPlatformIds,
  });

  static final Map<String, List<String>> _categoryOrder = {
    'General': ['phone', 'sms', 'email', 'website', 'address'],
    'Messaging': [
      'whatsapp',
      'telegram',
      'line',
      'wechat',
      'zalo',
      'kakaotalk',
      'qq',
      'viber'
    ],
    'Social Media': [
      'facebook',
      'instagram',
      'linkedin',
      'tiktok',
      'threads',
      'twitter',
      'snapchat',
      'tumblr',
      'linkedin_company',
      'mastodon',
      'bluesky',
      'weibo',
      'naver',
      'pinterest',
      'red',
      'lemon8',
      'douyin'
    ],
    'App Stores & Dev': ['googlePlay', 'appStore', 'github', 'gitlab'],
    'Others': [
      'youtube',
      'twitch',
      'discord',
      'steam',
      'reddit',
      'googleReviews',
      'shopee',
      'lazada',
      'amazon',
      'etsy',
      'behance',
      'dribbble'
    ]
  };

  Map<String, List<SocialPlatform>> _categorizedPlatforms() {
    final availablePlatforms = SocialPlatforms.platforms
        .where((p) => !selectedPlatformIds.contains(p.id))
        .toList();

    return Map.fromEntries(
      _categoryOrder.entries
          .map((entry) => MapEntry(
                entry.key,
                entry.value
                    .where((id) => availablePlatforms.any((p) => p.id == id))
                    .map((id) =>
                        availablePlatforms.firstWhere((p) => p.id == id))
                    .toList()))
          .where((entry) => entry.value.isNotEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final categories = _categorizedPlatforms();
    
    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: isDesktop ? 900 : double.infinity,
        ),
        child: isDesktop 
          ? _buildDesktopLayout(context, categories, isDarkMode)
          : _buildMobileLayout(context, categories, isDarkMode),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context, 
    Map<String, List<SocialPlatform>> categories,
    bool isDarkMode,
  ) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Social Platform',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/social_icon_illustration.png',
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All platforms have been added',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Social Platform',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          TabBar(
            tabs: categories.keys
                .map((cat) => Tab(text: cat))
                .toList(),
            isScrollable: true,
          ),
          Expanded(
            child: TabBarView(
              children: categories.entries.map((category) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: category.value.length,
                    itemBuilder: (context, i) => _buildPlatformTile(
                      context,
                      category.value[i],
                      isDarkMode,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Map<String, List<SocialPlatform>> categories,
    bool isDarkMode,
  ) {
      final nonEmptyCategories = categories.entries.toList();
    return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Social Platform',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: nonEmptyCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/social_icon_illustration.png',
                              width: 200,
                              height: 200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'All platforms have been added',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: nonEmptyCategories.length,
                        itemBuilder: (context, index) {
                          final category = nonEmptyCategories[index];
                          final platforms = category.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  category.key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: platforms.length,
                                itemBuilder: (context, i) => _buildPlatformTile(
                                  context,
                                  platforms[i],
                                  isDarkMode,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
  }

  Widget _buildPlatformTile(
      BuildContext context, SocialPlatform platform, bool isDarkMode) {
    return InkWell(
      onTap: () => Navigator.pop(context, platform),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (platform.icon != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Icon(
                  platform.icon,
                  size: 24,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              )
            else if (platform.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SvgPicture.asset(
                  platform.imagePath!,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    isDarkMode ? Colors.white : Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  platform.name,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}