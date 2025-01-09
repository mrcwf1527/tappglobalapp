// lib/widgets/digital_profile/desktop/desktop_preview.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../screens/digital_profile/edit_digital_profile_screen.dart';
import 'profile_preview.dart';
import '../../../providers/digital_profile_provider.dart';

class DesktopPreview extends StatelessWidget {
  const DesktopPreview({super.key});

  Future<void> _copyLink(BuildContext context, String username) async {
    final link = 'http://localhost:50000/$username';
    await Clipboard.setData(ClipboardData(text: link));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, _) => LayoutBuilder(
        builder: (context, constraints) {
          Widget buildButtons() {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(
                        'http://localhost:50000/${provider.profileData.username}');
                    await launchUrl(url);
                  },
                  icon: FaIcon(
                    FontAwesomeIcons.upRightFromSquare,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                  label: Text(
                    'Preview Digital Profile',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide.none,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(8.0),
                        right: Radius.circular(0.0),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _copyLink(context, provider.profileData.username),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide.none,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.all(12.0),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.copy,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ShareDialog(
                        username: provider.profileData.username,
                        displayName: provider.profileData.displayName ?? '',
                        profileImageUrl: provider.profileData.profileImageUrl,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide.none,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(0.0),
                        right: Radius.circular(8.0),
                      ),
                    ),
                    padding: const EdgeInsets.all(12.0),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.share,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            );
          }

          if (constraints.maxHeight >= 966) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 56),
                buildButtons(),
                const SizedBox(height: 24),
                const ProfilePreview(),
              ],
            );
          }

          return SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 64),
                buildButtons(),
                const Expanded(
                  child: ProfilePreview(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ShareDialog extends StatelessWidget {
  final String username;
  final String displayName;
  final String? profileImageUrl;

  const ShareDialog({
    required this.username,
    required this.displayName,
    this.profileImageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            BorderedQRView(
              data: 'https://l.tappglobal.app/$username',
              profileImageUrl: profileImageUrl,
            ),
            const SizedBox(height: 24),
            _buildOption(
              context,
              'Copy Link',
              FontAwesomeIcons.copy,
              () => _copyLink(context),
              subtitle: 'https://l.tappglobal.app/$username',
            ),
            _buildOption(
              context,
              'Download Contact Card',
              FontAwesomeIcons.fileExport,
              () => _downloadContactCard(context),
            ),
            _buildOption(
              context,
              'Add to Wallet',
              FontAwesomeIcons.wallet,
              () => _addToWallet(context),
            ),
            _buildOption(
              context,
              'Save QR Code',
              FontAwesomeIcons.download,
              () => _saveQRCode(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            FaIcon(icon, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white60
                                : Colors.black45,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    final link = 'https://l.tappglobal.app/$username';
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // TODO: Implement vCard download
  void _downloadContactCard(BuildContext context) {}

  // TODO: Implement Apple/Google Wallet integration
  void _addToWallet(BuildContext context) {}

  // TODO: Implement QR code download
  void _saveQRCode(BuildContext context) {}
}