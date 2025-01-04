// lib/widgets/digital_profile/banner_upload.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/digital_profile_provider.dart';

class BannerUpload extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String)? onImageUploaded;

  const BannerUpload({
    super.key, 
    this.currentImageUrl,
    this.onImageUploaded,
  });

  @override
  State<BannerUpload> createState() => _BannerUploadState();
}

class _BannerUploadState extends State<BannerUpload> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  Uint8List? _croppedBytes;
  bool _isLoading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      if (kIsWeb) {
        _imageBytes = await image.readAsBytes();
      } else {
        final file = File(image.path);
        _imageBytes = await file.readAsBytes();
      }
      
      if (_imageBytes != null) {
        _showCropDialog();
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

    void _showCropDialog() {
    final cropController = CropController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, 
                      color: isDarkMode ? Colors.white : Colors.black
                    ),
                    onPressed: () {
                      _imageBytes = null;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 400,
              width: 400,
              child: Crop(
                image: _imageBytes!,
                controller: cropController,
                aspectRatio: 2.0,
                baseColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
                maskColor: (isDarkMode ? Colors.white : Colors.black).withAlpha(153),
                onCropped: (result) {
                  switch (result) {
                    case CropSuccess(:final croppedImage):
                      setState(() => _croppedBytes = croppedImage);
                      Navigator.pop(context);
                      _uploadImage();
                    case CropFailure():
                      _showErrorDialog('Failed to crop image');
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => cropController.crop(),
                 style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Crop'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _uploadImage() async {
    if (_croppedBytes == null) return;

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('banner_images/banner.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': 'banner-image'},
      );

      final uploadTask = ref.putData(_croppedBytes!, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

       if (mounted) {
        final provider = context.read<DigitalProfileProvider>();
        provider.updateProfile(bannerImageUrl: downloadUrl);
        await provider.saveProfile();
      }
    } catch (e) {
      _showErrorDialog('Error uploading image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _imageBytes = null;
          _croppedBytes = null;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Banner Image',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 2.6,
          child: InkWell(
            onTap: () => _showImageSourceDialog(),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.grey[200],
                 borderRadius: BorderRadius.circular(8),
              ),
              child: _buildContent(),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          value: _uploadProgress.isFinite ? _uploadProgress : null
        ),
      );
    }

    if (widget.currentImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.currentImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 24),
        const SizedBox(height: 4),
        Text(
          'Select file or\ndrag and drop',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }


   void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}