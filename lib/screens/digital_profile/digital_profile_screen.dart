// lib/screens/digital_profile/digital_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../widgets/responsive_layout.dart';
import '../../providers/digital_profile_provider.dart';
import 'edit_digital_profile_screen.dart';
import 'dart:async';

class DigitalProfileScreen extends StatefulWidget {
  const DigitalProfileScreen({super.key});

  @override
  State<DigitalProfileScreen> createState() => _DigitalProfileScreenState();
}

class _DigitalProfileScreenState extends State<DigitalProfileScreen> {
  // Add this dialog when + button is clicked
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
                                    builder: (context) => ChangeNotifierProvider(
                                      create: (_) => DigitalProfileProvider()..loadProfile(profileId),
                                      child: EditDigitalProfileScreen(profileId: profileId),
                                    ),
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
    return ResponsiveLayout(
      mobileLayout: _DigitalProfileMobileLayout(showUsernameDialog: _showUsernameDialog),
      desktopLayout: const _DigitalProfileDesktopLayout(),
    );
  }
}

class _DigitalProfileMobileLayout extends StatelessWidget {
  final VoidCallback showUsernameDialog;
  const _DigitalProfileMobileLayout({required this.showUsernameDialog});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/digital_profile_illustration.png',
              width: 200,
              height: 200,
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
  const _DigitalProfileDesktopLayout();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/digital_profile_illustration.png',
                width: 300,
                height: 300,
              ),
              const SizedBox(height: 24),
              Text(
                'Create your first digital profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFD9D9D9),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to create new profile screen
                  },
                  icon: const Icon(Icons.add, color: Colors.black, size: 24),
                  label: const Text('Create New Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}