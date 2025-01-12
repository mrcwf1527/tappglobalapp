// lib/widgets/digital_profile/blocks/link_image_upload.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LinkImageUpload extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String) onImageUploaded;
  final String linkId;

  const LinkImageUpload({
    super.key,
    this.currentImageUrl,
    required this.onImageUploaded,
    required this.linkId,
  });

  @override
  State<LinkImageUpload> createState() => _LinkImageUploadState();
}

class _LinkImageUploadState extends State<LinkImageUpload> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isLoading = true);
      final imageBytes = await image.readAsBytes();
      await _uploadImage(imageBytes);
    } catch (e) {
      _showError('Error picking image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImage(Uint8List imageBytes) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('link_images/${widget.linkId}.jpg');

      await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await ref.getDownloadURL();
      widget.onImageUploaded(downloadUrl);
    } catch (e) {
      _showError('Error uploading image: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: _isLoading ? null : _pickAndUploadImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
          border: Border.all(
            color: isDarkMode ? Colors.white24 : Colors.black12,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
        FaIcon(
          FontAwesomeIcons.image,
          size: 20,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white54
              : Colors.black54,
        ),
      ],
    );
  }
}