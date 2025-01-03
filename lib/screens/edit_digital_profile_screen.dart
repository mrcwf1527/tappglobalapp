// lib/screens/edit_digital_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../models/social_platform.dart';
import '../models/country_code.dart';
import '../widgets/digital_profile/social_media_selector.dart';
import '../widgets/selectors/country_code_selector.dart';

class EditDigitalProfileScreen extends StatefulWidget {
  const EditDigitalProfileScreen({super.key});

  @override
  State<EditDigitalProfileScreen> createState() => _EditDigitalProfileScreenState();
}

class _EditDigitalProfileScreenState extends State<EditDigitalProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _bioController = TextEditingController();
  final List<SocialPlatform> _selectedPlatforms = [];
  final Map<String, TextEditingController> _phoneControllers = {};
  final Map<String, ValueNotifier<CountryCode>> _countryNotifiers = {};
  final Map<String, TextEditingController> _socialControllers = {}; // Added for social platforms

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Initialize controllers for each platform
    for (var platform in SocialPlatforms.platforms) {
      _socialControllers[platform.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _locationController.dispose();
    _jobTitleController.dispose();
    _companyNameController.dispose();
    _bioController.dispose();
    for (var controller in _phoneControllers.values) {
      controller.removeListener(() {}); // Remove listeners
      controller.dispose();
    }
    for (var controller in _socialControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializePhoneController(String platformId, CountryCode defaultCountry) {
    if (!_phoneControllers.containsKey(platformId)) {
      final controller = TextEditingController();
      _phoneControllers[platformId] = controller;
      _countryNotifiers[platformId] = ValueNotifier(defaultCountry);

      controller.addListener(() {
        final value = controller.text;
        String formattedNumber = value;
        final countryCode = _countryNotifiers[platformId]!.value;

        // Remove the country code if present at start
        if (value.startsWith(countryCode.dialCode.replaceAll('+', ''))) {
          formattedNumber = value.substring(countryCode.dialCode.replaceAll('+', '').length);
        }
        // Remove leading zero
        if (formattedNumber.startsWith('0')) {
          formattedNumber = formattedNumber.substring(1);
        }

        try {
          final phoneNumber = PhoneNumber.parse(
            formattedNumber,
            destinationCountry: IsoCode.values.firstWhere(
              (code) => code.name == countryCode.code.toUpperCase()
            ),
          );
          
          if (phoneNumber.isValid()) {
            controller.value = controller.value.copyWith(
              text: phoneNumber.nsn,
              selection: TextSelection.collapsed(offset: phoneNumber.nsn.length)
            );
          }
        } catch (e) {
          // Keep the formatted number as is
          controller.value = controller.value.copyWith(
            text: formattedNumber,
            selection: TextSelection.collapsed(offset: formattedNumber.length)
          );
        }
      });
    }
  }

  void _addSocialPlatform() async {
    final result = await showDialog<SocialPlatform>(
      context: context,
      builder: (context) => SocialMediaSelector(
        selectedPlatformIds: _selectedPlatforms.map((p) => p.id).toList(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPlatforms.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Profile'),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Header'),
            Tab(text: 'Blocks'),
            Tab(text: 'Insights'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHeaderTab(isDarkMode),
          const Center(child: Text('Blocks')),
          const Center(child: Text('Insights')),
          const Center(child: Text('Settings')),
        ],
      ),
    );
  }

  Widget _buildHeaderTab(bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        // This will dismiss keyboard when tapping outside text fields
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildUrlTextField(),
            const SizedBox(height: 24),
            _buildImageUploadSection(),
            const SizedBox(height: 24),
            _buildProfileInfoSection(),
            const SizedBox(height: 24),
            _buildSocialLinksSection(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlTextField() {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: 'Profile Link',
        prefixText: 'https://l.tappglobal.app/',
        prefixStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.black54,
          fontSize: 16,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).inputDecorationTheme.border,
        enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
        focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        LengthLimitingTextInputFormatter(50),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Image',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 24),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Logo',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_outlined, size: 24),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Banner Image',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 2.6,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'Select file or drag and drop',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileInfoSection() {
    return Column(
      children: [
        _buildFormField('Display Name', _displayNameController, 50),
        const SizedBox(height: 16),
        _buildFormField('Location', _locationController, 50),
        const SizedBox(height: 16),
        _buildFormField('Job Title', _jobTitleController, 100),
        const SizedBox(height: 16),
        _buildFormField('Company Name', _companyNameController, 100),
        const SizedBox(height: 16),
        _buildBioField(),
      ],
    );
  }

  Widget _buildFormField(
      String label, TextEditingController controller, int maxLength) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).inputDecorationTheme.border,
        enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
        focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
      ),
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      decoration: InputDecoration(
        labelText: 'Bio',
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: Theme.of(context).inputDecorationTheme.border,
        enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
        focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
      ),
      maxLines: null,
      minLines: 1,
      maxLength: 50,
      buildCounter: (context,
          {required currentLength, required isFocused, maxLength}) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text('$currentLength/50 words', textAlign: TextAlign.end),
        );
      },
    );
  }

  Widget _buildSocialLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Social Icons',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Your social icons will appear below your header text',
            style: TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        if (_selectedPlatforms.isNotEmpty) ...[
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _selectedPlatforms.removeAt(oldIndex);
                _selectedPlatforms.insert(newIndex, item);
              });
            },
            buildDefaultDragHandles: false,
            children: _selectedPlatforms.asMap().entries.map((entry) {
              final platform = entry.value;
              return _buildSocialField(entry.key, platform);
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        ElevatedButton(
          onPressed: _addSocialPlatform,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFFD9D9D9) 
              : Colors.black,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black 
                  : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Social Icons',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black 
                    : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialField(int index, SocialPlatform platform) {
    if (!_phoneControllers.containsKey(platform.id)) {
      _phoneControllers[platform.id] = TextEditingController();
      // Set United States as default
      _countryNotifiers[platform.id] = ValueNotifier(CountryCodes.codes.firstWhere((code) => code.code == 'US'));
      // Add default +1 to text field
      _phoneControllers[platform.id]!.text = '';
    }
    final phoneController = _phoneControllers[platform.id]!;
    final selectedCountry = _countryNotifiers[platform.id]!;

    if (platform.requiresCountryCode && platform.numbersOnly) {
      _initializePhoneController(
        platform.id, 
        CountryCodes.codes.firstWhere((code) => code.code == 'US')
      );
      return Container(
        key: ValueKey(platform.id),
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_indicator),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: Theme.of(context).inputDecorationTheme.border,
                  enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                  prefixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 40,
                        child: Center(
                          child: platform.icon != null 
          ? FaIcon(platform.icon, size: 20)
          : SvgPicture.asset(
              platform.imagePath!,
              width: 20,
              height: 20,
            ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final selected = await showDialog<CountryCode>(
                            context: context,
                            builder: (context) => const CountrySearchDialog(),
                          );
                          if (selected != null) {
                            selectedCountry.value = selected;
                            setState(() {
                              _selectedPlatforms[index] = platform.copyWith(
                                value: phoneController.text
                              );
                            });
                          }
                        },
                        child: Text(
                          selectedCountry.value.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  prefixText: '${selectedCountry.value.dialCode} ',
                ),
                onChanged: (value) {
                  String formattedNumber = value;
                  // Remove the country code if present at start
                  if (value.startsWith(selectedCountry.value.dialCode.replaceAll('+', ''))) {
                    formattedNumber = value.substring(selectedCountry.value.dialCode.replaceAll('+', '').length);
                  }
                  // Remove leading zero
                  if (formattedNumber.startsWith('0')) {
                    formattedNumber = formattedNumber.substring(1);
                  }
                  
                  try {
                    final phoneNumber = PhoneNumber.parse(
                      formattedNumber,
                      destinationCountry: IsoCode.values.firstWhere(
                        (code) => code.name == selectedCountry.value.code.toUpperCase()
                      ),
                    );
                    
                    setState(() {
                      // Update the controller text to show formatted number
                      phoneController.text = phoneNumber.nsn;
                      _selectedPlatforms[index] = platform.copyWith(
                        value: '${selectedCountry.value.dialCode}${phoneNumber.nsn}'
                      );
                    });
                  } catch (e) {
                    setState(() {
                      phoneController.text = formattedNumber;
                      _selectedPlatforms[index] = platform.copyWith(
                        value: '${selectedCountry.value.dialCode}$formattedNumber'
                      );
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a phone number';

                  try {
                    final phoneNumber = PhoneNumber.parse(
                      value,
                      // Get the ISO code for the selected country
                      destinationCountry: IsoCode.values.firstWhere(
                        (code) => code.name == selectedCountry.value.code.toUpperCase()
                      ),
                    );

                    // Use the library's validation
                    if (!phoneNumber.isValid()) {
                      return 'Please enter a valid phone number for ${selectedCountry.value.name}';
                    }
                  } catch (e) {
                    return 'Invalid phone number format';
                  }
                  return null;
                }
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _selectedPlatforms.removeAt(index)),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      );
    }

    if (platform.id == 'email') {
      return Container(
        key: ValueKey(platform.id),
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_indicator),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: platform.value,
                decoration: InputDecoration(
                  labelText: platform.name,
                  prefixIcon: SizedBox(
                    width: 40,
                    child: Center(
                      child: platform.icon != null 
                        ? FaIcon(platform.icon, size: 20)
                        : SvgPicture.asset(
                            platform.imagePath!,
                            width: 20,
                            height: 20,
                        ),
                    ),
                  ),
                  prefixText: platform.prefix,
                  hintText: platform.placeholder,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: Theme.of(context).inputDecorationTheme.border,
                  enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  errorText: platform.value != null && 
                            !platform.validationPattern!.hasMatch(platform.value!) 
                            ? 'Please enter a valid email address' 
                            : null,
                ),
                onChanged: (value) {
                  final parsedValue = platform.parseUrl(value);
                  setState(() {
                    _selectedPlatforms[index] = platform.copyWith(
                      value: parsedValue,
                    );
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!platform.validationPattern!.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _selectedPlatforms.removeAt(index)),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      );
    }

    // For non-WhatsApp and non-email platforms
      return Container(
        key: ValueKey(platform.id),
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_indicator),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _socialControllers[platform.id], // Using the new controller
                decoration: InputDecoration(
                  labelText: platform.name,
                  prefixIcon: SizedBox(
                    width: 40,
                    child: Center(
                      child: platform.icon != null 
                        ? FaIcon(platform.icon, size: 20)
                        : SvgPicture.asset(
                            platform.imagePath!,
                            width: 20,
                            height: 20,
                        ),
                    ),
                  ),
                  prefixText: platform.prefix,
                  hintText: platform.placeholder,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: Theme.of(context).inputDecorationTheme.border,
                  enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                  focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              onChanged: (value) {
  if (value.isEmpty) return;
  
  if (platform.urlHandlingType == UrlHandlingType.usernameOnly) {
    // For username-only platforms, store URL but display username
    final username = platform.parseUrl(value);
    final fullUrl = platform.standardUrlFormat?.replaceAll('{username}', username ?? '');
    
    setState(() {
      _selectedPlatforms[index] = platform.copyWith(value: fullUrl);
      // Update display text to show only username
      _socialControllers[platform.id]?.text = username ?? '';
    });
  } else {
    // Other platforms remain the same
    final parsedValue = platform.parseUrl(value);
    setState(() {
      _selectedPlatforms[index] = platform.copyWith(value: parsedValue);
    });
  }
},
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _selectedPlatforms.removeAt(index)),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      );
  }
}