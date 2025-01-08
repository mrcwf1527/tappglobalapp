// lib/screens/digital_profile/digital_profile_screen.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/digital_profile_provider.dart';
import 'edit_digital_profile_screen.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/responsive_layout.dart';

class DigitalProfileScreen extends StatefulWidget {
  const DigitalProfileScreen({super.key});

  @override
  State<DigitalProfileScreen> createState() => _DigitalProfileScreenState();
}

class _DigitalProfileScreenState extends State<DigitalProfileScreen> {
  Future<void> _showUsernameDialog() async {
    final textController = TextEditingController();
    String? validationMessage;
    bool? isAvailable;
    Timer? debounceTimer;

    void checkUsername(String username, StateSetter setState) {
      if (debounceTimer?.isActive ?? false) debounceTimer?.cancel();

      debounceTimer = Timer(const Duration(milliseconds: 500), () async {
        if (username.isEmpty) {
          setState(() {
            validationMessage = null;
            isAvailable = null;
          });
          return;
        }

        if (!RegExp(r'^[a-z0-9]{6,30}$').hasMatch(username)) {
          setState(() {
            validationMessage =
                'Must be 6-30 characters with lowercase letters and numbers only';
            isAvailable = false;
          });
          return;
        }

        final error = await Provider.of<DigitalProfileProvider>(context, listen: false)
            .checkUsernameAvailability(username);

        setState(() {
          validationMessage = error ?? 'Username is available';
          isAvailable = error == null;
        });
      });
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Digital Profile',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose Username',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: textController,
                        onChanged: (value) => checkUsername(value, setState),
                        decoration: InputDecoration(
                          prefixText: 'l.tappglobal.app/',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9]')),
                          LengthLimitingTextInputFormatter(30),
                        ],
                      ),
                      if (validationMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                isAvailable == true ? Icons.check_circle : Icons.error,
                                color: isAvailable == true ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 300,
                                child: Text(
                                  validationMessage!,
                                  style: TextStyle(
                                    color: isAvailable == true ? Colors.green : Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: isAvailable == true ? () async {
                          final provider = Provider.of<DigitalProfileProvider>(
                            context,
                            listen: false,
                          );
                          final profileId = await provider.reserveUsername(textController.text);
                          if (profileId != null) {
                             if (context.mounted) {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => EditDigitalProfileScreen(profileId: profileId),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return child;
                                      },
                                  )
                                );
                              }
                          }
                        } : null,
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: _DigitalProfileMobileLayout(showUsernameDialog: _showUsernameDialog),
      desktopLayout: _DigitalProfileDesktopLayout(showUsernameDialog: _showUsernameDialog),
    );
  }
}

class _DigitalProfileMobileLayout extends StatelessWidget {
  final VoidCallback showUsernameDialog;
  
  const _DigitalProfileMobileLayout({required this.showUsernameDialog});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<DigitalProfileProvider>(context, listen: false);

    return Scaffold(
      body: StreamBuilder<List<DigitalProfileData>>(
        stream: provider.getProfilesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profiles = snapshot.data ?? [];
          
          if (profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/digital_profile_illustration.png',
                    width: 200, height: 200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create your first digital profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return GestureDetector(
                onTap: () {
                  if (!context.mounted) return;
                  final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
                  provider.loadProfile(profile.id);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => EditDigitalProfileScreen(profileId: profile.id),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return child;
                        },
                      )
                    );
                },
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            profile.profileImageUrl?.isNotEmpty == true
                              ? CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(profile.profileImageUrl!),
                                )
                              : const CircleAvatar(
                                  radius: 30,
                                  child: Icon(Icons.person, size: 36),
                                ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.displayName ?? profile.username,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (profile.jobTitle?.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.jobTitle!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                  if (profile.companyName?.isNotEmpty == true) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      profile.companyName!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (profile.socialPlatforms.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 76),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: profile.socialPlatforms.map((platform) {
                                return platform.icon != null
                                  ? Icon(
                                      platform.icon, 
                                      size: 20,
                                      color: Colors.grey[600],
                                    )
                                  : platform.imagePath != null
                                    ? SvgPicture.asset(
                                        platform.imagePath!,
                                        width: 20,
                                        height: 20,
                                        colorFilter: ColorFilter.mode(
                                          Colors.grey[600]!,
                                          BlendMode.srcIn,
                                        ),
                                      )
                                    : const SizedBox();
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (profile.bio?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(left: 76),
                            child: Text(
                              profile.bio!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showUsernameDialog,
        backgroundColor: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
        child: Icon(
          Icons.add,
          color: isDarkMode ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

class _DigitalProfileDesktopLayout extends StatelessWidget {
  final VoidCallback showUsernameDialog;
  static const double sideNavWidth = 250.0;
  
  const _DigitalProfileDesktopLayout({required this.showUsernameDialog});

  double _getCardWidth(BuildContext context) {
    final totalWidth = MediaQuery.of(context).size.width - sideNavWidth;
    final padding = 48.0;
    final spacing = 24.0;
    
    if (totalWidth >= 2310) return (totalWidth - padding - spacing * 4) / 5;
    if (totalWidth >= 1670) return (totalWidth - padding - spacing * 3) / 4;
    if (totalWidth >= 1030) return (totalWidth - padding - spacing * 2) / 3;
    if (totalWidth >= 774) return (totalWidth - padding - spacing) / 2;
    return totalWidth - padding;
  }

  List<DigitalProfileData> _filterProfiles(List<DigitalProfileData> profiles, String query) {
    if (query.isEmpty) return profiles;
    
    query = query.toLowerCase();
    return profiles.where((profile) {
      return (profile.displayName?.toLowerCase().contains(query) ?? false) ||
             (profile.jobTitle?.toLowerCase().contains(query) ?? false) ||
             (profile.companyName?.toLowerCase().contains(query) ?? false) ||
             (profile.bio?.toLowerCase().contains(query) ?? false) ||
             (profile.location?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Widget _buildProfileCard(DigitalProfileData profile, BuildContext context) {
    return GestureDetector(
      onTap: () {
      if (!context.mounted) return;
      final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
      provider.loadProfile(profile.id);
        Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => EditDigitalProfileScreen(profileId: profile.id),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return child;
                },
            )
        );
    },
      child: Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              profile.profileImageUrl?.isNotEmpty == true
                ? CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(profile.profileImageUrl!),
                  )
                : const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
              const SizedBox(height: 24),
              Text(
                profile.displayName ?? profile.username,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (profile.jobTitle?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  profile.jobTitle!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (profile.companyName?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  profile.companyName!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
              if (profile.socialPlatforms.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: profile.socialPlatforms.map((platform) {
                    return platform.icon != null
                      ? Icon(platform.icon, size: 20, color: Colors.grey[600])
                      : platform.imagePath != null
                        ? SvgPicture.asset(
                            platform.imagePath!,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              Colors.grey[600]!,
                              BlendMode.srcIn,
                            ),
                          )
                        : const SizedBox();
                  }).toList(),
                ),
              ],
              if (profile.bio?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Text(
                  profile.bio!,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

   @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
    final searchController = TextEditingController();
    final searchNotifier = ValueNotifier<String>('');

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => searchNotifier.value = value,
                    decoration: InputDecoration(
                      hintText: 'Search by name, job, company, bio or location...',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: const Icon(Icons.search),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 180,
                    maxWidth: 180,
                    minHeight: 48,
                    maxHeight: 48,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: showUsernameDialog,
                    icon: Icon(
                      Icons.add,
                      size: 20,
                      color: isDarkMode ? Colors.black : Colors.white,
                    ),
                    label: const Text('Add New Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DigitalProfileData>>(
              stream: provider.getProfilesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ValueListenableBuilder<String>(
                  valueListenable: searchNotifier,
                  builder: (context, searchQuery, _) {
                    final allProfiles = snapshot.data ?? [];
                    final filteredProfiles = _filterProfiles(allProfiles, searchQuery);
                    
                    if (filteredProfiles.isEmpty) {
                      if (allProfiles.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/digital_profile_illustration.png',
                                width: 200, height: 200,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Create your first digital profile',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No profiles match your search',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = _getCardWidth(context);
                          final cardsPerRow = ((constraints.maxWidth + 24) / (cardWidth + 24)).floor();
                          
                          return Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: List.generate((filteredProfiles.length / cardsPerRow).ceil(), (rowIndex) {
                              final rowStart = rowIndex * cardsPerRow;
                              final rowEnd = (rowStart + cardsPerRow).clamp(0, filteredProfiles.length);
                              final rowProfiles = filteredProfiles.sublist(rowStart, rowEnd);
                              
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: rowProfiles.map((profile) =>
                                    SizedBox(
                                      width: cardWidth,
                                      child: _buildProfileCard(profile, context),
                                    ),
                                  ).toList(),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}