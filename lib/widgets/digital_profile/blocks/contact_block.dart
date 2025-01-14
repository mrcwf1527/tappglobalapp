// lib/widgets/digital_profile/blocks/contact_block.dart
// Widget for managing contact cards including profile photo upload, basic info (name, job, company), phone numbers, and emails with Firebase integration and real-time updates.
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:provider/provider.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../../../models/block.dart';
import '../../../models/country_code.dart';
import '../../../models/social_platform.dart';
import '../../../providers/digital_profile_provider.dart';
import '../../selectors/country_code_selector.dart';
import '../../../utils/debouncer.dart';

class ContactBlock extends StatefulWidget {
  final Block block;
  final Function(Block) onBlockUpdated;
  final Function(String) onBlockDeleted;

  const ContactBlock({
    super.key,
    required this.block,
    required this.onBlockUpdated,
    required this.onBlockDeleted,
  });

  @override
  State<ContactBlock> createState() => _ContactBlockState();
}

class _ContactBlockState extends State<ContactBlock> {
  final _debouncer = Debouncer();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyNameController;
  final Map<String, TextEditingController> _phoneControllers = {};
  final Map<String, TextEditingController> _emailControllers = {};
  final Map<String, ValueNotifier<CountryCode>> _countryNotifiers = {};
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.block.contents.firstOrNull?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.block.contents.firstOrNull?.lastName ?? '');
    _jobTitleController = TextEditingController(text: widget.block.contents.firstOrNull?.jobTitle ?? '');
    _companyNameController = TextEditingController(text: widget.block.contents.firstOrNull?.companyName ?? '');

    // Delay initialization to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeContacts();
      }
    });
  }

  void _initializeContacts() {
    final content = widget.block.contents.firstOrNull;
    final provider = Provider.of<DigitalProfileProvider>(context, listen: false);

    // Only consider it a new block if there's no content at all
    final isNewBlock = content == null || (
      (content.firstName?.isEmpty ?? true) && 
      (content.lastName?.isEmpty ?? true) && 
      (content.jobTitle?.isEmpty ?? true) && 
      (content.companyName?.isEmpty ?? true) &&
      (content.imageUrl?.isEmpty ?? true) &&
      ((content.metadata?['phones'] as List?)?.isEmpty ?? true) &&
      ((content.metadata?['emails'] as List?)?.isEmpty ?? true)
    );

    if (isNewBlock) {
      // New block - pull data from digital profile
      try {
        final profileData = provider.profileData;
        final phones = _extractPhoneNumbers(profileData.socialPlatforms);
        final emails = _extractEmails(profileData.socialPlatforms);

        // Create metadata with phones and emails
        final metadata = {
          'phones': phones,
          'emails': emails,
        };

        final newContent = BlockContent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: '',
          url: '',
          firstName: profileData.displayName,
          lastName: '',
          jobTitle: profileData.jobTitle,
          companyName: profileData.companyName,
          metadata: metadata,
          isPrimaryPhone: phones.isNotEmpty ? phones[0]['isPrimary'] : null,
          isPrimaryEmail: emails.isNotEmpty ? emails[0]['isPrimary'] : null,
        );

        // Update UI first
        setState(() {
          _firstNameController.text = profileData.displayName ?? '';
          _jobTitleController.text = profileData.jobTitle ?? '';
          _companyNameController.text = profileData.companyName ?? '';

          // Initialize phone controllers
          for (var phone in phones) {
            final id = phone['id'] as String;
            final dialCode = phone['dialCode'] as String;
            final number = _stripCountryCode(phone['number'] as String, dialCode);
            _phoneControllers[id] = TextEditingController(text: number);
            _countryNotifiers[id] = ValueNotifier(
              CountryCodes.findByCode(phone['countryCode']) ?? CountryCodes.getDefault()
            );
          }

          for (var email in emails) {
            final id = email['id'] as String;
            _emailControllers[id] = TextEditingController(text: email['address']);
          }
        });

        _updateBlock(newContent);

        if (profileData.profileImageUrl?.isNotEmpty == true) {
          _processProfileImage(profileData.profileImageUrl!, newContent.id);
        }
      } catch (e) {
        debugPrint('Error initializing contacts: $e');
      }
      return;
    }

    // Load existing content
    setState(() {
      _firstNameController.text = content.firstName ?? '';
      _lastNameController.text = content.lastName ?? '';
      _jobTitleController.text = content.jobTitle ?? '';
      _companyNameController.text = content.companyName ?? '';

      // Initialize phone controllers
      final phones = content.metadata?['phones'] as List? ?? [];
      for (var phone in phones) {
        final id = phone['id'] as String;
        _phoneControllers[id] = TextEditingController(text: phone['number']);
        _countryNotifiers[id] = ValueNotifier(
          CountryCodes.findByCode(phone['countryCode']) ?? CountryCodes.getDefault()
        );
      }

      // Initialize email controllers  
      final emails = content.metadata?['emails'] as List? ?? [];
      for (var email in emails) {
        final id = email['id'] as String;
        _emailControllers[id] = TextEditingController(text: email['address']);
      }
    });
  }

  String _stripCountryCode(String phoneNumber, String dialCode) {
    if (phoneNumber.startsWith(dialCode)) {
      return phoneNumber.substring(dialCode.length).trim();
    }
    return phoneNumber;
  }

  Future<void> _processProfileImage(String sourceUrl, String contentId) async {
    if (mounted) {
      setState(() => _isUploading = true);
    }

    try {
      final response = await http.get(Uri.parse(sourceUrl));
      if (response.statusCode != 200) throw Exception('Failed to fetch image');

      final imageBytes = await decodeImageFromList(response.bodyBytes);
      Uint8List processedBytes;

      if (response.bodyBytes.length > 224 * 1024 || 
          imageBytes.width > 400 || 
          imageBytes.height > 400) {
        final resizedImage = await _resizeImage(imageBytes, 400, 400);
        processedBytes = await _compressImage(resizedImage);
      } else {
        processedBytes = response.bodyBytes;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('contact_images/${widget.block.id}.jpg');

      await ref.putData(processedBytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await ref.getDownloadURL();

      if (mounted) {
        final content = widget.block.contents.first;
        final updatedContent = content.copyWith(imageUrl: downloadUrl);

        // Add these lines to update the local state
        setState(() {
          widget.block.contents[0] = updatedContent;
        });

        _updateBlock(updatedContent);
      }

    } catch (e) {
      debugPrint('Error processing profile image: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  List<Map<String, dynamic>> _extractPhoneNumbers(List<SocialPlatform> platforms) {
    final phoneOrder = ['phone', 'sms', 'whatsapp', 'viber', 'zalo'];
    final phones = <Map<String, dynamic>>[];
  
    for (var platformId in phoneOrder) {
      // Changed to handle orElse case differently
      try {
        final platform = platforms.firstWhere(
          (p) => p.id == platformId && p.value != null && p.value!.isNotEmpty,
        );
    
        phones.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'number': platform.value!,
          'countryCode': 'MY',
          'dialCode': '+60',
          'isPrimary': phones.isEmpty
        });
      } catch (e) {
        // Skip if platform not found
        continue;
      }
    }
  
    return phones;
  }

  List<Map<String, dynamic>> _extractEmails(List<SocialPlatform> platforms) {
    try {
      final emailPlatform = platforms.firstWhere(
        (p) => p.id == 'email' && p.value != null && p.value!.isNotEmpty,
      );
  
      return [{
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'address': emailPlatform.value!,
        'isPrimary': true
      }];
    } catch (e) {
      return [];
    }
  }

  void _updateBlock(BlockContent content) {
    // Get current form values
    final updatedContent = content.copyWith(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      jobTitle: _jobTitleController.text,
      companyName: _companyNameController.text,
      metadata: {
        'phones': _phoneControllers.entries.map((entry) {
          final id = entry.key;
          final controller = entry.value;
          final countryCode = _countryNotifiers[id]!.value;
          return {
            'id': id,
            'number': '${countryCode.dialCode}${controller.text}',
            'countryCode': countryCode.code,
            'dialCode': countryCode.dialCode,
            'isPrimary': _phoneControllers.keys.first == id,
          };
        }).toList(),
        'emails': _emailControllers.entries.map((entry) => {
          'id': entry.key,
          'address': entry.value.text,
          'isPrimary': _emailControllers.keys.first == entry.key,
        }).toList(),
      }
    );

    final updatedBlock = widget.block.copyWith(
      contents: [updatedContent],
      sequence: widget.block.sequence,
    );
    widget.onBlockUpdated(updatedBlock);
  }

  void _updateContent({
    String? firstName,
    String? lastName,
    String? jobTitle,
    String? companyName,
    Map<String, dynamic>? metadata,
  }) {
    final existingContent = widget.block.contents.firstOrNull ?? BlockContent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      url: '',
    );

    // Get current phones and emails if not provided in metadata
    final updatedMetadata = metadata ?? {
      ...existingContent.metadata ?? {},
      'phones': _phoneControllers.entries.map((entry) {
        final id = entry.key;
        final controller = entry.value;
        final countryCode = _countryNotifiers[id]!.value;
        return {
          'id': id,
          'number': '${countryCode.dialCode}${controller.text}',
          'countryCode': countryCode.code,
          'dialCode': countryCode.dialCode,
          'isPrimary': _phoneControllers.keys.first == id,
        };
      }).toList(),
      'emails': _emailControllers.entries.map((entry) => {
        'id': entry.key,
        'address': entry.value.text,
        'isPrimary': _emailControllers.keys.first == entry.key,
      }).toList(),
    };

    final updatedContent = existingContent.copyWith(
      firstName: firstName ?? _firstNameController.text,
      lastName: lastName ?? _lastNameController.text,
      jobTitle: jobTitle ?? _jobTitleController.text,
      companyName: companyName ?? _companyNameController.text,
      metadata: updatedMetadata,
    );

    _updateBlock(updatedContent);
  }

  void _addPhoneNumber() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _phoneControllers[id] = TextEditingController();
      _countryNotifiers[id] = ValueNotifier(CountryCodes.getDefault());
    });
    _updateContent();
  }

  void _addEmail() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _emailControllers[id] = TextEditingController();
    });
    _updateContent();
  }

  void _removePhone(String id) {
    setState(() {
      _phoneControllers.remove(id);
      _countryNotifiers.remove(id);
    });
    _updateContent();
  }

  void _removeEmail(String id) {
    setState(() {
      _emailControllers.remove(id);
    });
    _updateContent();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBasicInfoSection(isDarkMode),
        const SizedBox(height: 24),
        _buildPhoneNumbersSection(isDarkMode),
        const SizedBox(height: 24),
        _buildEmailsSection(isDarkMode),
      ],
    );
  }

  Widget _buildBasicInfoSection(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Basic Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProfileImageUpload(isDarkMode),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name *',
                    hintText: 'Enter first name',
                  ),
                  onChanged: (value) => _debouncer.run(() => _updateContent(firstName: value)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Enter last name',
                  ),
                  onChanged: (value) => _debouncer.run(() => _updateContent(lastName: value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _jobTitleController,
            decoration: const InputDecoration(
              labelText: 'Job Title',
              hintText: 'Enter job title (optional)',
            ),
             onChanged: (value) => _debouncer.run(() => _updateContent(jobTitle: value)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _companyNameController,
            decoration: const InputDecoration(
              labelText: 'Company Name',
              hintText: 'Enter company name (optional)',
            ),
            onChanged: (value) => _debouncer.run(() => _updateContent(companyName: value)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageUpload(bool isDarkMode) {
    final content = widget.block.contents.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact Photo',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isUploading ? null : _pickAndUploadImage,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
            ),
            child: _isUploading
              ? Center(child: CircularProgressIndicator())
              : content?.imageUrl != null 
                ? ClipOval(
                    child: Image.network(
                      content!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    ),
                  )
                : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.person_outline, size: 24),
        const SizedBox(height: 4),
        Text(
          'Add Photo',
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

  Future<void> _pickAndUploadImage() async {
  _showImageSourceDialog();
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

Future<void> _pickImage(ImageSource source) async {
  try {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    final imageBytes = await image.readAsBytes();
    _showCropDialog(imageBytes);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

void _showCropDialog(Uint8List imageBytes) {
  final cropController = CropController();
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  bool isCropping = false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
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
                        color: isDarkMode ? Colors.white : Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 400,
              width: 400,
              child: Crop(
                image: imageBytes,
                controller: cropController,
                aspectRatio: 1,
                baseColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
                maskColor: (isDarkMode ? Colors.white : Colors.black).withAlpha(153),
                onCropped: (result) {
                  switch (result) {
                    case CropSuccess(:final croppedImage):
                      _handleCroppedImage(croppedImage);
                      Navigator.pop(context);
                    case CropFailure():
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to crop image')),
                      );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: isCropping ? null : () async {
                  setDialogState(() => isCropping = true);
                  cropController.crop();
                  if (mounted) setDialogState(() => isCropping = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
                  foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isCropping 
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.black : Colors.white,
                        ),
                      ),
                    )
                  : const Text('Crop'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _handleCroppedImage(Uint8List croppedBytes) async {
  setState(() => _isUploading = true);

  try {
    if (croppedBytes.length > 224 * 1024) {
      final decodedImage = await decodeImageFromList(croppedBytes);
      final resizedImage = await _resizeImage(decodedImage, 400, 400);
      final compressedBytes = await _compressImage(resizedImage);
      await _uploadImage(compressedBytes);
    } else {
      await _uploadImage(croppedBytes);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _isUploading = false);
  }
}

  Future<Uint8List> _compressImage(ui.Image image) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(image, Offset.zero, Paint());
    final picture = recorder.endRecording();
    final rasterImage = await picture.toImage(image.width, image.height);
    final byteData = await rasterImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<ui.Image> _resizeImage(ui.Image image, int targetWidth, int targetHeight) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
  
    final ratioX = targetWidth / image.width;
    final ratioY = targetHeight / image.height;
    final ratio = math.min(ratioX, ratioY);
  
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

  Future<void> _uploadImage(Uint8List imageBytes) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(userId)
        .child('contact_images/${widget.block.id}.jpg');

    await ref.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
    final downloadUrl = await ref.getDownloadURL();

    final content = widget.block.contents.first;
    final updatedContent = content.copyWith(
      imageUrl: downloadUrl,
      firstName: content.firstName,
      lastName: content.lastName,
      jobTitle: content.jobTitle,
      companyName: content.companyName,
      metadata: content.metadata,
      isPrimaryEmail: content.isPrimaryEmail,
      isPrimaryPhone: content.isPrimaryPhone
    );

    setState(() {
      widget.block.contents[0] = updatedContent;
    });
  
    final updatedBlock = widget.block.copyWith(
      contents: [updatedContent],
      sequence: widget.block.sequence,
    );
  
    widget.onBlockUpdated(updatedBlock);
  }

  Widget _buildPhoneNumbersSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phone Numbers',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_phoneControllers.isEmpty)
          Center(
            child: Text(
              'Add at least one phone number',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ReorderableListView(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            setState(() {
              final entries = _phoneControllers.entries.toList();
              final item = entries.removeAt(oldIndex);
              entries.insert(newIndex, item);
              
              _phoneControllers.clear();
              for (var entry in entries) {
                _phoneControllers[entry.key] = entry.value;
              }
              
              final countryEntries = _countryNotifiers.entries.toList();
              final countryItem = countryEntries.removeAt(oldIndex);
              countryEntries.insert(newIndex, countryItem);
              
              _countryNotifiers.clear();
              for (var entry in countryEntries) {
                _countryNotifiers[entry.key] = entry.value;
              }
            });
            _updateContent();
          },
          children: [
            for (var entry in _phoneControllers.entries)
              _buildPhoneNumberField(
                key: ValueKey(entry.key),
                id: entry.key,
                controller: entry.value,
                countryNotifier: _countryNotifiers[entry.key]!,
                index: _phoneControllers.keys.toList().indexOf(entry.key),
                isDarkMode: isDarkMode,
              ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _addPhoneNumber,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
            foregroundColor: isDarkMode ? Colors.black : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.plus,
                size: 16,
                color: isDarkMode ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Phone Number',
                style: TextStyle(
                  color: isDarkMode ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField({
    required Key key,
    required String id,
    required TextEditingController controller,
    required ValueNotifier<CountryCode> countryNotifier,
    required int index,
    required bool isDarkMode,
  }) {
    // Set initial stripped value
    if (controller.text.startsWith(countryNotifier.value.dialCode)) {
      controller.text = _stripCountryCode(controller.text, countryNotifier.value.dialCode);
    }

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: index == 0 ? 'Primary Phone Number *' : 'Phone Number *',
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountryCodeSelectorButton(
                      selectedCountry: countryNotifier.value,
                      onSelect: (country) {
                        countryNotifier.value = country;
                        _updateContent();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                prefixText: '${countryNotifier.value.dialCode} ',
              ),
              onChanged: (value) => _debouncer.run(() {
                // Save with country code
                final fullNumber = '${countryNotifier.value.dialCode}$value';
                final currentPhones = _phoneControllers.entries.map((entry) {
                  final id = entry.key;
                  final controller = entry.value;
                  final countryCode = _countryNotifiers[id]!.value;
                  return {
                    'id': id,
                    'number': id == id ? fullNumber : '${countryCode.dialCode}${controller.text}',
                    'countryCode': countryCode.code,
                    'dialCode': countryCode.dialCode,
                    'isPrimary': _phoneControllers.keys.first == id,
                  };
                }).toList();

                _updateContent(metadata: {
                  ...widget.block.contents.first.metadata ?? {},
                  'phones': currentPhones,
                });
              }),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                try {
                  final fullNumber = '${countryNotifier.value.dialCode}$value';
                  final phoneNumber = PhoneNumber.parse(
                    fullNumber,
                    destinationCountry: IsoCode.values.firstWhere(
                      (code) => code.name == countryNotifier.value.code.toUpperCase()
                    ),
                  );
                  if (!phoneNumber.isValid()) {
                    return 'Invalid phone number';
                  }
                } catch (e) {
                  return 'Invalid phone number format';
                }
                return null;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _phoneControllers.length > 1 ? () => _removePhone(id) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailsSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Email Addresses',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            setState(() {
              final entries = _emailControllers.entries.toList();
              final item = entries.removeAt(oldIndex);
              entries.insert(newIndex, item);
              
              _emailControllers.clear();
              for (var entry in entries) {
                _emailControllers[entry.key] = entry.value;
              }
            });
            _updateContent();
          },
          children: [
            for (var entry in _emailControllers.entries)
              _buildEmailField(
                key: ValueKey(entry.key),
                id: entry.key,
                controller: entry.value,
                index: _emailControllers.keys.toList().indexOf(entry.key),
                isDarkMode: isDarkMode,
              ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _addEmail,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
            foregroundColor: isDarkMode ? Colors.black : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.plus,
                size: 16,
                color: isDarkMode ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Email Address',
                style: TextStyle(
                  color: isDarkMode ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField({
    required Key key,
    required String id,
    required TextEditingController controller,
    required int index,
    required bool isDarkMode,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: index == 0 ? 'Primary Email Address' : 'Email Address',
                prefixIcon: const Icon(Icons.email),
              ),
              onChanged: (value) => _debouncer.run(() => _updateContent()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Email is optional
                }
                final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
                if (!emailRegex.hasMatch(value)) {
                  return 'Invalid email address';
                }
                return null;
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _removeEmail(id),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jobTitleController.dispose();
    _companyNameController.dispose();
    for (var controller in _phoneControllers.values) {
      controller.dispose();
    }
    for (var controller in _emailControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}