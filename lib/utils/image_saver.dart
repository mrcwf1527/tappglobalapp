// lib/utils/image_saver.dart
// Utility class for saving images to device storage or downloading in web browsers, with platform-specific implementations for mobile gallery and web downloads.
import 'package:flutter/foundation.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:universal_html/html.dart' as html;

class ImageSaveUtil {
  static Future<void> saveImage(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..download = filename;
      anchor.click();
      html.Url.revokeObjectUrl(url);
    } else {
      final result = await ImageGallerySaver.saveImage(bytes);
      if (result['isSuccess'] != true) {
        throw Exception('Failed to save image');
      }
    }
  }
}