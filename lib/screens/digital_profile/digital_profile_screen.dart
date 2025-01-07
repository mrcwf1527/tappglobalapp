// lib/screens/digital_profile/digital_profile_screen.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/digital_profile_provider.dart';
import 'edit_digital_profile_screen.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

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
                                  MaterialPageRoute(
                                    builder: (context) => EditDigitalProfileScreen(profileId: profileId),
                                  ),
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
  return _DigitalProfileMobileLayout(showUsernameDialog: _showUsernameDialog);
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
  
                  // Preload profile data
                  provider.loadProfile(profile.id);
  
                  // Navigate immediately
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDigitalProfileScreen(
                        profileId: profile.id,
                      ),
                    ),
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