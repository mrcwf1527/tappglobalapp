// lib/widgets/digital_profile/social_icons.dart
// Profile Components: Social media links management
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../selectors/social_media_selector.dart';
import '../selectors/country_code_selector.dart';
import '../../models/country_code.dart';
import '../../models/social_platform.dart';
import '../../providers/digital_profile_provider.dart';

class SocialIcons extends StatefulWidget {
  const SocialIcons({super.key});

  @override
  State<SocialIcons> createState() => _SocialIconsState();
}

class _SocialIconsState extends State<SocialIcons> {
  final Map<String, TextEditingController> _phoneControllers = {};
  final Map<String, ValueNotifier<CountryCode>> _countryNotifiers = {};
  final Map<String, TextEditingController> _socialControllers = {};
  final Map<String, Timer?> _debounceTimers = {}; // Store timers for each field
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<DigitalProfileProvider>();
    
    for (var entry in provider.profileData.socialPlatforms.asMap().entries) {
      final platform = entry.value;
      final index = entry.key;

      if (platform.requiresCountryCode && platform.numbersOnly) {
        // Initialize phone controllers
        _phoneControllers[platform.id] = TextEditingController();
        _countryNotifiers[platform.id] = ValueNotifier(
          _getCountryFromValue(platform.value)
        );
        
        if (platform.value != null) {
          // Extract phone number without country code
          final dialCode = _countryNotifiers[platform.id]!.value.dialCode;
          final number = platform.value!.replaceFirst(dialCode, '');
          _phoneControllers[platform.id]!.text = number;
        }
      } else {
        _socialControllers[platform.id] = TextEditingController(text: platform.value);
        _focusNodes[platform.id] = FocusNode()..addListener(() {
          final focusNode = _focusNodes[platform.id];
          if (focusNode != null && !focusNode.hasFocus) {
            _handleFocusLost(platform, index);
          }
        });
      }
    }
  }

  void _handleFocusLost(SocialPlatform platform, int index) {
    // Add website, address, bluesky, etc to the check
    if (!(platform.id == 'facebook' || 
          platform.id == 'linkedin' || 
          platform.id == 'linkedin_company' ||
          platform.id == 'website' ||
          platform.id == 'address' ||
          platform.id == 'bluesky' ||
          platform.id == 'discord' ||
          platform.id == 'googleReviews' ||
          platform.id == 'shopee' ||
          platform.id == 'lazada' ||
          platform.id == 'amazon' ||
          platform.id == 'googlePlay' ||
          platform.id == 'appStore' ||
          platform.id == 'line' ||
          platform.id == 'weibo' ||
          platform.id == 'naver'
        )) {
      return;
    }
    
    final controller = _socialControllers[platform.id];
    if (controller == null || controller.text.isEmpty) return;

    if (!controller.text.contains('/')) {
      String prefix = '';
      switch (platform.id) {
        case 'facebook':
          prefix = 'facebook.com/';
          break;
        case 'linkedin':
          prefix = 'linkedin.com/in/';
          break;
        case 'linkedin_company':
          prefix = 'linkedin.com/company/';
          break;
        case 'website':
          prefix = ''; // Remove https:// prefix addition
          break;
        case 'address':
          prefix = ''; // No prefix for address
          break;
        case 'bluesky':
          prefix = 'bsky.app/profile/';
          break;
        case 'discord':
          prefix = 'discord.gg/';
          break;
        case 'googleReviews':
          prefix = ''; // No prefix for googleReviews
          break;
        case 'shopee':
          prefix = '';
          break;
        case 'lazada':
          prefix = '';
          break;
        case 'amazon':
          prefix = '';
          break;
        case 'googlePlay':
          prefix = '';
          break;
        case 'appStore':
          prefix = '';
          break;
        case 'line':
          prefix = '';
          break;
        case 'weibo':
          prefix = '';
          break;
        case 'naver':
          prefix = '';
          break;
      }
      final newValue = prefix + controller.text;
      controller.text = newValue;
      // Update platforms with the new value
      final platforms = [...context.read<DigitalProfileProvider>().profileData.socialPlatforms];
      platforms[index] = platform.copyWith(value: newValue);
      context.read<DigitalProfileProvider>().updateSocialPlatforms(platforms);
    }
  }

  // Add this helper method
  CountryCode _getCountryFromValue(String? value) {
    if (value == null || value.isEmpty) {
      return CountryCodes.getDefault();  
    }
    
    // Find matching country code
    for (var country in CountryCodes.codes) {
      if (value.startsWith(country.dialCode)) {
        return country;
      }
    }
    
    return CountryCodes.getDefault();
  }

  @override
  void dispose() {
    for (var controller in _phoneControllers.values) {
      controller.dispose();
    }
    for (var controller in _socialControllers.values) {
      controller.dispose();
    }
    for (var timer in _debounceTimers.values) {
      timer?.cancel();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _initializePhoneController(String platformId, CountryCode defaultCountry) {
    if (!_phoneControllers.containsKey(platformId)) {
      _phoneControllers[platformId] = TextEditingController();
      _countryNotifiers[platformId] = ValueNotifier(defaultCountry);
    }
  }

  void _addSocialPlatform() async {
    final provider = context.read<DigitalProfileProvider>();
    final result = await showDialog<SocialPlatform>(
      context: context,
      builder: (context) => SocialMediaSelector(
        selectedPlatformIds: provider.profileData.socialPlatforms
            .map((p) => p.id)
            .toList(),
      ),
    );

    if (result != null) {
      _socialControllers[result.id] = TextEditingController();
      final index = provider.profileData.socialPlatforms.length; // Get the new index
      _focusNodes[result.id] = FocusNode()..addListener(() {
        if (!_focusNodes[result.id]!.hasFocus) {
          _handleFocusLost(result, index);
        }
      });
      provider.updateSocialPlatforms([
        ...provider.profileData.socialPlatforms,
        result,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Social Icons',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your social icons will appear below your header text',
              style: TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          if (provider.profileData.socialPlatforms.isNotEmpty) ...[
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                final platforms = [...provider.profileData.socialPlatforms];
                final item = platforms.removeAt(oldIndex);
                platforms.insert(newIndex, item);
                provider.updateSocialPlatforms(platforms);
              },
              buildDefaultDragHandles: false,
              children: provider.profileData.socialPlatforms
                  .asMap()
                  .entries
                  .map((entry) => _buildSocialField(entry.key, entry.value))
                  .toList(),
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
      ),
    );
  }

  Widget _buildSocialField(int index, SocialPlatform platform) {
    final provider = context.read<DigitalProfileProvider>();

    if (platform.requiresCountryCode && platform.numbersOnly) {
      _initializePhoneController(
        platform.id, 
        CountryCodes.codes.firstWhere((code) => code.code == 'US')
      );
      final phoneController = _phoneControllers[platform.id]!;
      final selectedCountry = _countryNotifiers[platform.id]!;

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
                            // Clear the phone number field
                            phoneController.clear();
                            // Update platforms with empty value for this entry
                            final platforms = [...provider.profileData.socialPlatforms];
                            platforms[index] = platform.copyWith(value: '');
                            provider.updateSocialPlatforms(platforms);
                          }
                        },
                        child: selectedCountry.value.getFlagWidget(
                          width: 24, 
                          height: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  prefixText: '${selectedCountry.value.dialCode} ',
                ),
                onChanged: (value) {
                  String formattedNumber = value;
                  if (value.startsWith(selectedCountry.value.dialCode.replaceAll('+', ''))) {
                    formattedNumber = value.substring(selectedCountry.value.dialCode.replaceAll('+', '').length);
                  }
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
                    
                    final platforms = [...provider.profileData.socialPlatforms];
                    phoneController.text = phoneNumber.nsn;
                    platforms[index] = platform.copyWith(
                      value: '${selectedCountry.value.dialCode}${phoneNumber.nsn}'
                    );
                    
                    if (_debounceTimers[platform.id]?.isActive ?? false) {
                      _debounceTimers[platform.id]?.cancel();
                    }
                    _debounceTimers[platform.id] = Timer(const Duration(milliseconds: 500), () {
                      provider.updateSocialPlatforms(platforms);
                    });
                  } catch (e) {
                    final platforms = [...provider.profileData.socialPlatforms];
                    phoneController.text = formattedNumber;
                    platforms[index] = platform.copyWith(
                      value: '${selectedCountry.value.dialCode}$formattedNumber'
                    );
                    if (_debounceTimers[platform.id]?.isActive ?? false) {
                      _debounceTimers[platform.id]?.cancel();
                    }
                    _debounceTimers[platform.id] = Timer(const Duration(milliseconds: 500), () {
                      provider.updateSocialPlatforms(platforms);
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a phone number';

                  try {
                    final phoneNumber = PhoneNumber.parse(
                      value,
                      destinationCountry: IsoCode.values.firstWhere(
                        (code) => code.name == selectedCountry.value.code.toUpperCase()
                      ),
                    );

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
              onPressed: () {
                final platforms = [...provider.profileData.socialPlatforms];
                platforms.removeAt(index);
                provider.updateSocialPlatforms(platforms);
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      );
    }

    // Email platform handling
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
                  final platforms = [...provider.profileData.socialPlatforms];
                  platforms[index] = platform.copyWith(value: parsedValue);
                  if (_debounceTimers[platform.id]?.isActive ?? false) {
                    _debounceTimers[platform.id]?.cancel();
                  }
                  _debounceTimers[platform.id] = Timer(const Duration(milliseconds: 500), () {
                    provider.updateSocialPlatforms(platforms);
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
              onPressed: () {
                final platforms = [...provider.profileData.socialPlatforms];
                platforms.removeAt(index);
                provider.updateSocialPlatforms(platforms);
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      );
    }

    // Other social platforms
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
              controller: _socialControllers[platform.id],
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
                hintText: _socialControllers[platform.id]?.text.isEmpty ?? true 
                  ? platform.placeholder
                  : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: Theme.of(context).inputDecorationTheme.border,
                enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixText: platform.prefix,
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {});
                  return;
                }
                
                final parsedValue = platform.parseUrl(value);
                if (parsedValue != value && parsedValue != null) {
                  _socialControllers[platform.id]?.text = parsedValue;
                  _socialControllers[platform.id]?.selection = TextSelection.collapsed(
                    offset: parsedValue.length
                  );
                }
                
                final platforms = [...provider.profileData.socialPlatforms];
                platforms[index] = platform.copyWith(value: parsedValue);
                
                if (_debounceTimers[platform.id]?.isActive ?? false) {
                  _debounceTimers[platform.id]?.cancel();
                }
                _debounceTimers[platform.id] = Timer(const Duration(milliseconds: 500), () {
                  provider.updateSocialPlatforms(platforms);
                });
              },
              focusNode: _focusNodes[platform.id],
              onTap: () {
                FocusScope.of(context).requestFocus(_focusNodes[platform.id]);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              final platforms = [...provider.profileData.socialPlatforms];
              platforms.removeAt(index);
              provider.updateSocialPlatforms(platforms);
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}