// lib/screens/business_card/edit_business_card_screen.dart
// Screen for editing scanned business card information with form fields and image preview, supporting multiple cards from a single scan.
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/s3_service.dart';

class EditBusinessCardScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final List<Map<String, dynamic>> extractedCards;
  final String? fileName;
  final Uint8List? originalImageBytes;

  const EditBusinessCardScreen({
    super.key,
    required this.imageBytes,
    this.originalImageBytes,
    required this.extractedCards,
    this.fileName,
  });

  @override
  State<EditBusinessCardScreen> createState() => _EditBusinessCardScreenState();
}

class _EditBusinessCardScreenState extends State<EditBusinessCardScreen> {
  final S3Service _s3Service = S3Service();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late List<Map<String, dynamic>> _cards;
  late int _currentCardIndex = 0;
  final bool _isSaving = false;
  bool _isSavingAll = false;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.extractedCards);
  }

  Future<void> _saveAllCards() async {
    if (!mounted) return;
    
    setState(() => _isSavingAll = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final String fileName = widget.fileName?.toLowerCase() ?? '';
      String url;
      
      if (fileName.endsWith('.pdf')) {
        // For PDF files, use the original bytes
        url = await _s3Service.uploadFile(
          fileBytes: widget.imageBytes,
          userId: userId,
          folder: 'business_cards',
          fileName: widget.fileName ?? 'document.pdf',
        );
      } else {
        // For images, always use original image bytes
        url = await _s3Service.uploadImage(
          imageBytes: widget.originalImageBytes!,
          userId: userId,
          folder: 'business_cards',
          fileName: DateTime.now().millisecondsSinceEpoch.toString(),
          maxSizeKB: 800,
        );
      }

      for (var card in _cards) {
        final cardData = {
          ...card,
          'userId': userId,
          'fileUrl': url,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        };
        await FirebaseFirestore.instance
            .collection('businessCards')
            .doc(userId)
            .collection('cards')
            .add(cardData);
      }

      if (mounted) {
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error saving cards: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  void _nextCard() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _currentCardIndex++;
        _formKey = GlobalKey<FormState>();
      });
    }
  }

  Widget _buildPreviewContent() {
    final String fileName = widget.fileName?.toLowerCase() ?? '';
    
    try {
      if (fileName.endsWith('.pdf')) {
        return GestureDetector(
          onTap: () => _showExpandedPreview(context),
          child: Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf, 
                  size: 48,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[700],
                ),
                const SizedBox(height: 12),
                Text(
                  'PDF File',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[700],
                  ),
                ),
                Text(
                  'Tap to download',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Image.memory(
        widget.imageBytes,
        height: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => ErrorPreviewContainer(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, 
                size: 48,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load preview',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );

    } catch (e) {
      return ErrorPreviewContainer(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, 
              size: 48,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(height: 12),
            Text(
              'Error loading preview',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showExpandedPreview(BuildContext context) async {
    if (!mounted) return;
    final currentContext = context;
    final navigator = Navigator.of(currentContext);
    final messenger = ScaffoldMessenger.of(currentContext);
    
    final String fileName = widget.fileName?.toLowerCase() ?? '';
    
    if (fileName.endsWith('.pdf')) {
      if (!kIsWeb) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          if (!mounted) return;
          
          final filePath = '${directory.path}/${widget.fileName}';
          final file = File(filePath);
          await file.writeAsBytes(widget.imageBytes);
          
          final url = Uri.file(filePath);
          final canLaunch = await canLaunchUrl(url);
          
          if (!mounted) return;
          if (canLaunch) {
            await launchUrl(url);
          } else {
            messenger.showSnackBar(
              const SnackBar(content: Text('Could not open file')),
            );
          }
        } catch (e) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('Error opening file: $e')),
          );
        }
      } else {
        // Web implementation remains the same
        try {
          final blob = html.Blob([widget.imageBytes], 'application/pdf');
          final url = html.Url.createObjectUrlFromBlob(blob);
          
          if (!mounted) return;
          final anchor = html.AnchorElement()
            ..href = url
            ..download = widget.fileName ?? 'document.pdf'
            ..style.display = 'none';
          
          html.document.body?.append(anchor);
          anchor.click();
          anchor.remove();
          html.Url.revokeObjectUrl(url);
        } catch (e) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text('Error downloading file: $e')),
          );
        }
      }
      return;
    }

    // Image preview handling
    if (!mounted) return;
    await showDialog(
      context: currentContext,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.loose,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(widget.imageBytes),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => navigator.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableImage() {
    return GestureDetector(
      onTap: () => _showExpandedPreview(context),
      child: Container( // Added Container for better tap detection
        color: Colors.transparent, // Makes entire area tappable
        child: _buildPreviewContent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        
        if (_currentCardIndex == 0) {
          final currentContext = context;
          final navigator = Navigator.of(currentContext);
          final shouldPop = await showDialog<bool>(
            context: currentContext,
            builder: (context) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text('If you go back, all changes will be lost.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          ) ?? false;
          
          if (shouldPop && mounted) {
            navigator.pop();
          }
        } else {
          setState(() {
            _currentCardIndex--;
            _formKey = GlobalKey<FormState>();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Card ${_currentCardIndex + 1}/${_cards.length}'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildExpandableImage(),
              const SizedBox(height: 16),
              _buildTextField('Name', 'name', _cards[_currentCardIndex]['name']),
              _buildTextField('Title', 'title', _cards[_currentCardIndex]['title']),
              _buildTextField('Company', 'brand_name', _cards[_currentCardIndex]['brand_name']),
              _buildTextField('Legal Name', 'legal_name', _cards[_currentCardIndex]['legal_name']),
              _buildTextField('Address', 'address', _cards[_currentCardIndex]['address']),
              _buildTextField('Website', 'website', _cards[_currentCardIndex]['website']),
              _buildTextField('Phone Number', 'phone', _cards[_currentCardIndex]['phone']),
              _buildTextField('Email Address', 'email', _cards[_currentCardIndex]['email']),
              if (_hasSocialMedia('social_media_personal')) 
                _buildSocialMediaFields('Personal Social Media', 'social_media_personal'),
              if (_hasSocialMedia('social_media_company'))
                _buildSocialMediaFields('Company Social Media', 'social_media_company'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving || _isSavingAll 
                  ? null 
                  : _currentCardIndex == _cards.length - 1 
                    ? _saveAllCards
                    : _nextCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.brightness == Brightness.light 
                    ? Colors.black 
                    : Colors.white,
                  foregroundColor: theme.brightness == Brightness.light 
                    ? Colors.white 
                    : Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving || _isSavingAll
                  ? const CircularProgressIndicator()
                  : Text(
                      _currentCardIndex == _cards.length - 1 
                        ? 'Save All Cards' 
                        : 'Next Card'
                    ),
              ),
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasSocialMedia(String field) {
    final socialMedia = Map<String, String>.from(_cards[_currentCardIndex][field] ?? {});
    return socialMedia.values.any((value) => value.isNotEmpty);
  }

  Widget _buildTextField(String label, String field, dynamic initialValue) {
    String value = '';
    if (initialValue is List) {
      value = initialValue.join(', ');
    } else {
      value = initialValue?.toString() ?? '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey('$field-$_currentCardIndex'),
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        onSaved: (value) {
          if (field == 'phone' || field == 'email') {
            _cards[_currentCardIndex][field] = value?.split(',').map((e) => e.trim()).toList() ?? [];
          } else {
            _cards[_currentCardIndex][field] = value ?? '';
          }
        },
      ),
    );
  }

  Widget _buildSocialMediaFields(String label, String field) {
    final socialMedia = Map<String, String>.from(_cards[_currentCardIndex][field] ?? {});
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        ...socialMedia.entries
            .where((e) => e.value.isNotEmpty)
            .map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              initialValue: entry.value,
              decoration: InputDecoration(labelText: entry.key),
              onSaved: (value) {
                if (value?.isNotEmpty ?? false) {
                  socialMedia[entry.key] = value!;
                  _cards[_currentCardIndex][field] = socialMedia;
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

class ErrorPreviewContainer extends Container {
  ErrorPreviewContainer({
    super.key,
    required super.child,
    super.height,
    super.width,
    super.margin,
    super.decoration,
  });
}