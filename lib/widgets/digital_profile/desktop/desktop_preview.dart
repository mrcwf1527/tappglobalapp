// lib/widgets/digital_profile/desktop/desktop_preview.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/digital_profile_provider.dart';
import 'package:web/web.dart' as web;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

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
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
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
                  color: Colors.black.withOpacity(0.1),
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