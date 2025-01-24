// lib/widgets/digital_profile/desktop/desktop_preview.dart
// Shows real-time preview of digital profile on desktop, Implements sharing functionality, Displays QR code for profile sharing
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'profile_preview.dart';
import '../../../models/block.dart';
import '../../../providers/digital_profile_provider.dart';
import '../../../screens/digital_profile/edit_digital_profile_screen.dart';
import '../../../utils/image_saver.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class DesktopPreview extends StatelessWidget {
  const DesktopPreview({super.key});

  Future<void> _copyLink(BuildContext context, String username) async {
    final link = 'https://tappglobal-app-profile.web.app/$username';
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
                        'https://tappglobal-app-profile.web.app/${provider.profileData.username}');
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

class ShareDialog extends StatefulWidget {
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
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final _qrKey = GlobalKey<BorderedQRViewState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, child) {
        final hasContactBlock = provider.profileData.blocks
            .any((block) => block.type == BlockType.contact);

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
                  key: _qrKey,
                  data: 'https://tappglobal-app-profile.web.app/${widget.username}',
                  profileImageUrl: widget.profileImageUrl,
                ),
                const SizedBox(height: 24),
                _buildOption(
                  context,
                  'Copy Link',
                  FontAwesomeIcons.copy,
                  () => _copyLink(context),
                  subtitle: 'https://tappglobal-app-profile.web.app/${widget.username}',
                ),
                if (hasContactBlock) _buildOption(
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
      },
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
    final link = 'https://tappglobal-app-profile.web.app/${widget.username}';
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

  Future<void> _downloadContactCard(BuildContext context) async {
    final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
  
    // Find contact block
    final contactBlock = provider.profileData.blocks
      .firstWhere((block) => block.type == BlockType.contact,
        orElse: () => throw Exception('No contact block found'));

    final content = contactBlock.contents.firstOrNull;
    if (content == null) return;

    // Generate vCard data
    final phones = (content.metadata?['phones'] as List? ?? []);
    final emails = (content.metadata?['emails'] as List? ?? []);

    final vCard = [
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN;CHARSET=UTF-8:${content.firstName ?? ''} ${content.lastName ?? ''}'.trim(),
      'N;CHARSET=UTF-8:${content.lastName ?? ''};${content.firstName ?? ''};;;',
      if (content.imageUrl?.isNotEmpty == true) 'PHOTO;MEDIATYPE=image/jpeg:${content.imageUrl}',
      ...emails.map((email) => 'EMAIL;CHARSET=UTF-8;type=WORK,INTERNET:${email['address']}'),
      ...phones.map((phone) => 'TEL;TYPE=CELL:${phone['number']}'),
      if (content.jobTitle?.isNotEmpty == true) 'TITLE;CHARSET=UTF-8:${content.jobTitle}',
      if (content.companyName?.isNotEmpty == true) 'ORG;CHARSET=UTF-8:${content.companyName}',
      'URL;type=TAPP! Digital Profile;CHARSET=UTF-8:https://l.tappglobal.app/${widget.username}',
      'END:VCARD'
    ].join('\n');

    if (kIsWeb) {
      final bytes = utf8.encode(vCard);
      final base64 = base64Encode(bytes);
      final dataUrl = 'data:text/vcard;base64,$base64';

      // Create filename from contact name
      final fileName = '${content.firstName ?? ''} ${content.lastName ?? ''}'.trim();
      
      // Create and click download link
      html.AnchorElement(href: dataUrl)
        ..setAttribute('download', '${fileName.isEmpty ? 'contact' : fileName}.vcf')
        ..click();
    } else {
      // For mobile platforms
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/contact.vcf');
      await file.writeAsString(vCard);
      await Share.shareXFiles([XFile(file.path)], text: 'Contact Information');
    }

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact card downloaded successfully'))
    );
  }

  // TODO: Implement Apple/Google Wallet integration
  void _addToWallet(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('Digital wallet integration will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQRCode(BuildContext context) async {
    try {
      // Validate QR key state
      if (_qrKey.currentState == null) {
        throw QRGenerationException('QR code component not initialized');
      }

      // Generate QR code bytes
      final bytes = await _qrKey.currentState?.exportQR();
      if (bytes == null) {
        throw QRGenerationException('Failed to generate QR code data');
      }

      // Save image
      try {
        await ImageSaveUtil.saveImage(
          bytes, 
          'tapp_qr_${widget.username}.png'
        );
      } catch (e) {
        throw ImageSaveException('Failed to save QR code: ${e.toString()}');
      }

      if (!context.mounted) return;
      
      Navigator.pop(context);
      _showSuccessMessage(context);

    } on QRGenerationException catch (e) {
      _handleError(context, e.message);
    } on ImageSaveException catch (e) {
      _handleError(context, e.message);
    } catch (e) {
      _handleError(context, 'Unexpected error occurred while saving QR code');
    }
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code saved successfully'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleError(BuildContext context, String message) {
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Custom exceptions for better error handling
class QRGenerationException implements Exception {
  final String message;
  QRGenerationException(this.message);
}

class ImageSaveException implements Exception {
  final String message;
  ImageSaveException(this.message);
}