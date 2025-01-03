// lib/screens/digital_profile/widgets/digital_profile/social_icons.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:provider/provider.dart';
import '../../../../models/social_platform.dart';
import '../selectors/social_media_selector.dart';
import '../../models/country_code.dart';
import '../selectors/country_code_selector.dart';
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

  @override
  void initState() {
    super.initState();
    final provider = context.read<DigitalProfileProvider>();
    
    for (var platform in provider.profileData.socialPlatforms) {
      _socialControllers[platform.id] = TextEditingController(text: platform.value);
    }
  }

  @override
  void dispose() {
    for (var controller in _phoneControllers.values) {
      controller.dispose();
    }
    for (var controller in _socialControllers.values) {
      controller.dispose();
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
                            final platforms = [...provider.profileData.socialPlatforms];
                            platforms[index] = platform.copyWith(
                              value: phoneController.text
                            );
                            provider.updateSocialPlatforms(platforms);
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
                    provider.updateSocialPlatforms(platforms);
                  } catch (e) {
                    final platforms = [...provider.profileData.socialPlatforms];
                    phoneController.text = formattedNumber;
                    platforms[index] = platform.copyWith(
                      value: '${selectedCountry.value.dialCode}$formattedNumber'
                    );
                    provider.updateSocialPlatforms(platforms);
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
                  final platforms = [...provider.profileData.socialPlatforms];
                  platforms[index] = platform.copyWith(value: parsedValue);
                  provider.updateSocialPlatforms(platforms);
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
                  final username = platform.parseUrl(value);
                  final fullUrl = platform.standardUrlFormat?.replaceAll('{username}', username ?? '');
                  
                  final platforms = [...provider.profileData.socialPlatforms];
                  platforms[index] = platform.copyWith(value: fullUrl);
                  provider.updateSocialPlatforms(platforms);
                  _socialControllers[platform.id]?.text = username ?? '';
                } else {
                  final parsedValue = platform.parseUrl(value);
                  final platforms = [...provider.profileData.socialPlatforms];
                  platforms[index] = platform.copyWith(value: parsedValue);
                  provider.updateSocialPlatforms(platforms);
                }
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