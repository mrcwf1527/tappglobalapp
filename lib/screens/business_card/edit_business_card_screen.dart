// lib/screens/business_card/edit_business_card_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/s3_service.dart';

class EditBusinessCardScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final List<Map<String, dynamic>> extractedCards;

  const EditBusinessCardScreen({
    super.key,
    required this.imageBytes,
    required this.extractedCards,
  });

  @override
  State<EditBusinessCardScreen> createState() => _EditBusinessCardScreenState();
}

class _EditBusinessCardScreenState extends State<EditBusinessCardScreen> {
  final S3Service _s3Service = S3Service();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Initialize here
  late List<Map<String, dynamic>> _cards;
  late int _currentCardIndex = 0;
  bool _isSaving = false;
  bool _isSavingAll = false;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.extractedCards);
  }

    Future<void> _saveAllCards() async {
    setState(() => _isSavingAll = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final imageUrl = await _s3Service.uploadImage(
        imageBytes: widget.imageBytes,
        userId: userId,
        folder: 'business_cards',
        fileName: DateTime.now().millisecondsSinceEpoch.toString(),
        maxSizeKB: 800,
      );

      for (var card in _cards) {
        final cardData = {
          ...card,
          'userId': userId,
          'imageUrl': imageUrl,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        };
        await FirebaseFirestore.instance.collection('businessCards').add(cardData);
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving cards: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSavingAll = false);
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final imageUrl = await _s3Service.uploadImage(
        imageBytes: widget.imageBytes,
        userId: userId,
        folder: 'business_cards',
        fileName: DateTime.now().millisecondsSinceEpoch.toString(),
        maxSizeKB: 800,
      );

      final cardData = {
        ..._cards[_currentCardIndex],
        'userId': userId,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };

      await FirebaseFirestore.instance
          .collection('businessCards')
          .add(cardData);

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving card: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _nextCard() {
    if (_formKey.currentState!.validate()) {
      // Save current form data
      _formKey.currentState!.save();
      
      // Move to next card
      setState(() {
        _currentCardIndex++;
        // Force rebuild of form fields with new data
        _formKey = GlobalKey<FormState>();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentCardIndex == 0) {
          return await showDialog(
            context: context,
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
        } else {
          setState(() {
            _currentCardIndex--;
            _formKey = GlobalKey<FormState>();
          });
          return false;
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
                  backgroundColor: Theme.of(context).brightness == Brightness.light 
                    ? Colors.black 
                    : Colors.white,
                  foregroundColor: Theme.of(context).brightness == Brightness.light 
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


  // Modified _buildTextField to handle list conversion and maintain single line input
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

  Widget _buildListField(String label, String field) {
    // Handle list initialization more carefully
    dynamic fieldValue = _cards[_currentCardIndex][field];
    List<String> values;
    
    if (fieldValue is List) {
      values = fieldValue.map((e) => e.toString()).toList();
    } else if (fieldValue is String) {
      values = [fieldValue];
    } else {
      values = [];
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        ...List.generate(values.length, (index) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('$field-$index-$_currentCardIndex'),
                    initialValue: values[index],
                    onSaved: (value) {
                      if (value?.isNotEmpty ?? false) {
                        values[index] = value!;
                        _cards[_currentCardIndex][field] = values;
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() {
                    values.add('');
                    _cards[_currentCardIndex][field] = values;
                  }),
                ),
                if (values.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => setState(() {
                      values.removeAt(index);
                      _cards[_currentCardIndex][field] = values;
                    }),
                  ),
              ],
            ),
          )
        ),
      ],
    );
  }


  Widget _buildSocialMediaFields(String label, String field) {
    final socialMedia = Map<String, String>.from(_cards[_currentCardIndex][field] ?? {});
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16), // Added padding
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
  
  Widget _buildExpandableImage() {
    return Center(
      child: GestureDetector(
        onTap: () => _showExpandedImage(context),
        child: Image.memory(
          widget.imageBytes, 
          height: 200, 
          fit: BoxFit.contain
        ),
      ),
    );
    }

  void _showExpandedImage(BuildContext context) {
    showDialog(
      context: context,
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
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}