import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/block.dart';
import '../../../models/country_code.dart';
import '../../selectors/country_code_selector.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
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
  final _debouncer = Debouncer(); // Add this line
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyNameController;
  final Map<String, TextEditingController> _phoneControllers = {};
  final Map<String, TextEditingController> _emailControllers = {};
  final Map<String, ValueNotifier<CountryCode>> _countryNotifiers = {};
  bool _initialized = false; // Add this line

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _jobTitleController = TextEditingController();
    _companyNameController = TextEditingController();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initializeContacts();
        _firstNameController.text = widget.block.contents.firstOrNull?.firstName ?? '';
        _lastNameController.text = widget.block.contents.firstOrNull?.lastName ?? '';
        _jobTitleController.text = widget.block.contents.firstOrNull?.jobTitle ?? '';
        _companyNameController.text = widget.block.contents.firstOrNull?.companyName ?? '';
    }
  }

  void _initializeContacts() {
    final content = widget.block.contents.firstOrNull;
    if (content == null) {
      final newContent = BlockContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        url: '',
        metadata: {
          'phones': [],
          'emails': [],
        }
      );
      _updateBlock(newContent);
      return;
    }

    // Initialize controllers with existing values
    _firstNameController.text = content.firstName ?? '';
    _lastNameController.text = content.lastName ?? '';
    _jobTitleController.text = content.jobTitle ?? '';
    _companyNameController.text = content.companyName ?? '';

    final phones = content.metadata?['phones'] as List? ?? [];
    final emails = content.metadata?['emails'] as List? ?? [];

    for (var phone in phones) {
      final id = phone['id'] as String;
      _phoneControllers[id] = TextEditingController(text: phone['number']);
      _countryNotifiers[id] = ValueNotifier(
        CountryCodes.findByCode(phone['countryCode']) ?? CountryCodes.getDefault()
      );
    }

    for (var email in emails) {
      final id = email['id'] as String;
      _emailControllers[id] = TextEditingController(text: email['address']);
    }
  }

  void _updateBlock(BlockContent content) {
    final updatedBlock = widget.block.copyWith(
      contents: [content],
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
    final existingContent = widget.block.contents.first;
  
    // Get current phones and emails metadata
    final currentPhones = _phoneControllers.entries.map((entry) {
      final id = entry.key;
      final controller = entry.value;
      final countryCode = _countryNotifiers[id]!.value;
      return {
        'id': id,
        'number': controller.text,
        'countryCode': countryCode.code,
        'dialCode': countryCode.dialCode,
        'isPrimary': _phoneControllers.keys.first == id,
      };
    }).toList();

    final currentEmails = _emailControllers.entries.map((entry) => {
      'id': entry.key,
      'address': entry.value.text,
      'isPrimary': _emailControllers.keys.first == entry.key,
    }).toList();

    // Create updated metadata preserving existing data
    final updatedMetadata = {
      ...existingContent.metadata ?? {},
      'phones': currentPhones,
      'emails': currentEmails,
    };

    final updatedContent = existingContent.copyWith(
      firstName: firstName ?? _firstNameController.text,
      lastName: lastName ?? _lastNameController.text,
      jobTitle: jobTitle ?? _jobTitleController.text,
      companyName: companyName ?? _companyNameController.text,
      metadata: metadata ?? updatedMetadata,
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
      padding: const EdgeInsets.only(top: 16), // Added top padding
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
              onChanged: (value) => _debouncer.run(() => _updateContent()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                try {
                  final phoneNumber = PhoneNumber.parse(
                    value,
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