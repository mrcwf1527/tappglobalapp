// lib/widgets/scan_bottom_sheet.dart
// Bottom sheet widget offering options to scan, upload, or import business cards with image cropping functionality.
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/gemini_service.dart';
import '../screens/business_card/edit_business_card_screen.dart';
import 'scanning_loading_screen.dart';

class ScanBottomSheet extends StatefulWidget {
  const ScanBottomSheet({super.key});

  @override
  State<ScanBottomSheet> createState() => _ScanBottomSheetState();
}

class _ScanBottomSheetState extends State<ScanBottomSheet> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  Uint8List? _imageBytes;
  Uint8List? _croppedBytes;
  final bool _isLoading = false;
  final _cropController = CropController(); // Added crop controller

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      _imageBytes = await image.readAsBytes();
      if (_imageBytes != null) {
        _showCropDialog();
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  void _showCropDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        insetPadding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text('', style: TextStyle(fontSize: 16)),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Crop(
                controller: _cropController,
                image: _imageBytes!,
                onCropped: (result) {
                  switch (result) {
                    case CropSuccess(:final croppedImage):
                      setState(() => _croppedBytes = croppedImage);
                      Navigator.pop(context);
                      _processImage();
                    case CropFailure():
                      _showErrorDialog('Failed to crop image');
                  }
                },
                baseColor: isDarkMode ? Colors.black : Colors.white,
                // Customize crop area appearance
                maskColor: isDarkMode 
                  ? Colors.white.withAlpha((0.2 * 255).toInt())
                  : Colors.black.withAlpha((0.2 * 255).toInt()),
                cornerDotBuilder: (size, edgeAlignment) => 
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white : Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: isDarkMode ? Colors.black : Colors.white,
              child: ElevatedButton(
                onPressed: () => _cropController.crop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.white : Colors.black,
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Crop'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImage() async {
    if (_croppedBytes == null) return;

    // Show full-screen loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ScanningLoadingScreen(),
    );

    try {
      final extractedData = await _geminiService.extractBusinessCard(_croppedBytes!);
      
      if (!mounted) return;
      
      // Close both bottom sheet and loading screen
      Navigator.pop(context); // Close loading screen
      Navigator.pop(context); // Close bottom sheet
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditBusinessCardScreen(
            imageBytes: _croppedBytes!,
            extractedCards: extractedData,
          ),
        ),
      );
    } catch (e) {
      // Close loading screen
      Navigator.pop(context);
      _showErrorDialog('Error processing image: $e');
    }
  }

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.first.bytes == null) return;
      final bytes = result.files.first.bytes!;
      final fileName = result.files.first.name; // Add this to preserve filename

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ScanningLoadingScreen(),
      );

      final extractedData = await _geminiService.extractFromPDF(bytes);
      
      if (!mounted) return;

      Navigator.pop(context); // Bottom sheet
      Navigator.pop(context); // Loading screen
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditBusinessCardScreen(
            imageBytes: bytes,          // Original PDF bytes preserved
            extractedCards: extractedData,
            fileName: fileName,         // Pass filename for S3 upload
          ),
        ),
      );

    } catch (e) {
      debugPrint('Import error: $e');
      if (!mounted) return;
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (_isLoading) 
            const CircularProgressIndicator()
          else
            Column(
              children: [
                const Text(
                  'Add Business Card',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOption(
                      icon: FontAwesomeIcons.camera,
                      label: 'Scan\nCard',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    _buildOption(
                      icon: FontAwesomeIcons.image,
                      label: 'Upload\nCard',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                    _buildOption(
                      icon: FontAwesomeIcons.file,
                      label: 'Import\nFile',
                      onTap: _importFile,
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[800] // Darker background for dark mode
                : Colors.grey[100], // Light background for light mode
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
              icon, 
              size: 24,
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white // White icon for dark mode
                : Colors.black, // Black icon for light mode
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white // White text for dark mode
                : Colors.black, // Black text for light mode
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}