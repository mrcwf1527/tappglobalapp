// lib/services/s3_service.dart
// Service class for handling AWS S3 file operations including uploading, deleting, and optimizing images with size/dimension restrictions.
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class S3Service {
  static final S3Service _instance = S3Service._internal();
  factory S3Service() => _instance;
  
  late S3 _s3;
  final _uuid = Uuid();
  
  S3Service._internal() {
    _s3 = S3(
      region: dotenv.env['AWS_REGION']!,
      credentials: AwsClientCredentials(
        accessKey: dotenv.env['AWS_ACCESS_KEY_ID']!,
        secretKey: dotenv.env['AWS_SECRET_ACCESS_KEY']!,
      ),
    );
  }

  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String userId,
    required String folder,
    required String fileName,
    required int maxSizeKB,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final optimizedBytes = await _optimizeImage(
        imageBytes,
        maxSizeKB: maxSizeKB,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      final extension = 'jpg';
      final uniqueId = _uuid.v4();
      final key = 'users/$userId/$folder/$uniqueId.$extension';

      await _s3.putObject(
        bucket: dotenv.env['AWS_BUCKET']!,
        key: key,
        body: optimizedBytes,
        contentType: 'image/jpeg',
      );

      return '${dotenv.env['AWS_DOMAIN']!.replaceFirst('{0}', dotenv.env['AWS_BUCKET']!)}$key';
    } catch (e) {
      debugPrint('S3 upload error: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final key = uri.path.substring(1); // Remove leading slash

      await _s3.deleteObject(
        bucket: dotenv.env['AWS_BUCKET']!,
        key: key,
      );
    } catch (e) {
      debugPrint('S3 delete error: $e');
      rethrow;
    }
  }

  Future<Uint8List> _optimizeImage(
    Uint8List imageBytes, {
    required int maxSizeKB,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final image = await decodeImageFromList(imageBytes);
    
    if (maxWidth != null || maxHeight != null) {
      final resized = await _resizeImage(
        image,
        maxWidth ?? image.width,
        maxHeight ?? image.height,
      );
      imageBytes = await _compressImage(resized);
    }

    if (imageBytes.length > maxSizeKB * 15360) {
      // Implement compression logic here
      // You can use packages like flutter_image_compress
      // For now, using basic compression
      final quality = (maxSizeKB * 15360 * 100 / imageBytes.length).round();
      final compressedImage = await _compressImage(image, quality: quality);
      return compressedImage;
    }

    return imageBytes;
  }

  Future<ui.Image> _resizeImage(ui.Image image, int targetWidth, int targetHeight) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final ratioX = targetWidth / image.width;
    final ratioY = targetHeight / image.height;
    final ratio = ratioX < ratioY ? ratioX : ratioY;
    
    final newWidth = (image.width * ratio).round();
    final newHeight = (image.height * ratio).round();
    
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      Paint(),
    );
    
    return recorder.endRecording().toImage(newWidth, newHeight);
  }

  Future<Uint8List> _compressImage(ui.Image image, {int quality = 85}) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}