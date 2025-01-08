// lib/widgets/digital_profile/desktop/desktop_preview.dart
// Under TAPP! Global Flutter Project
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:provider/provider.dart';
import '../../../providers/digital_profile_provider.dart';

class DesktopPreview extends StatefulWidget {
  const DesktopPreview({super.key});

  @override
  State<DesktopPreview> createState() => _DesktopPreviewState();
}

class _DesktopPreviewState extends State<DesktopPreview> {
  late final web.HTMLIFrameElement _iframeElement;

  @override
  void initState() {
    super.initState();
    _iframeElement = web.document.createElement('iframe') as web.HTMLIFrameElement
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    // Register the view factory using platformViewRegistry
    if (kIsWeb) {
      // Use the new platformViewRegistry from ui_web
      ui_web.platformViewRegistry.registerViewFactory(
        'preview-iframe',
        (int viewId) => _iframeElement,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, _) {
        // Determine if the app is running locally
          final bool isLocalhost = kIsWeb && (web.window.location.hostname == 'localhost' || web.window.location.hostname == '127.0.0.1');

        _iframeElement.src = isLocalhost
            ? 'http://localhost:50000/${provider.profileData.username}'
            : 'https://l.tappglobal.app/${provider.profileData.username}';

        return Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 375,
              maxHeight: 812,
            ),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).toInt()),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: kIsWeb
                  ? const HtmlElementView(viewType: 'preview-iframe')
                  : Container(),
            ),
          ),
        );
      },
    );
  }
}