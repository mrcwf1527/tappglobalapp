// lib/widgets/digital_profile/blocks/social_platform_block.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'link_image_upload.dart';
import '../../../models/block.dart';
import '../../../models/country_code.dart';
import '../../../models/social_platform.dart';
import '../../../providers/digital_profile_provider.dart';
import '../../selectors/social_media_selector.dart';
import '../../selectors/country_code_selector.dart';

class SocialPlatformBlock extends StatefulWidget {
  final Block block;
  final Function(Block) onBlockUpdated;
  final Function(String) onBlockDeleted;

  const SocialPlatformBlock({
    super.key,
    required this.block,
    required this.onBlockUpdated,
    required this.onBlockDeleted,
  });

  @override
  State<SocialPlatformBlock> createState() => _SocialPlatformBlockState();
}

class _SocialPlatformBlockState extends State<SocialPlatformBlock> {
  late List<BlockContent> _contents;
  late bool _isVisible;
  final Map<String, TextEditingController> _phoneControllers = {};
  final Map<String, ValueNotifier<CountryCode>> _countryNotifiers = {};
  final Map<String, TextEditingController> _socialControllers = {};
  final Map<String, TextEditingController> _titleControllers = {}; // Added title controllers
  final Map<String, TextEditingController> _subtitleControllers = {}; // Added subtitle controllers
  final Map<String, Timer?> _debounceTimers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _contents = List.from(widget.block.contents);
    _isVisible = widget.block.isVisible ?? true;
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var content in _contents) {
      final platform = SocialPlatform.fromMap({
        'id': content.metadata?['platformId'] ?? '',
        'value': content.url,
      });

      _titleControllers[content.id] = TextEditingController(text: content.title); // Initialize title
      _subtitleControllers[content.id] = TextEditingController(text: content.subtitle); // Initialize subtitle

      if (platform.requiresCountryCode && platform.numbersOnly) {
        _phoneControllers[content.id] = TextEditingController();
        _countryNotifiers[content.id] = ValueNotifier(_getCountryFromValue(content.url));

        if (content.url.isNotEmpty) {
          final dialCode = _countryNotifiers[content.id]!.value.dialCode;
          final number = content.url.replaceFirst(dialCode, '');
          _phoneControllers[content.id]!.text = number;
        }
      } else {
        _socialControllers[content.id] = TextEditingController(text: content.url);
        _focusNodes[content.id] = FocusNode()
          ..addListener(() {
            if (!_focusNodes[content.id]!.hasFocus) {
              _handleFocusLost(content);
            }
          });
      }
    }
  }

  CountryCode _getCountryFromValue(String value) {
    if (value.isEmpty) return CountryCodes.getDefault();

    for (var country in CountryCodes.codes) {
      if (value.startsWith(country.dialCode)) {
        return country;
      }
    }
    return CountryCodes.getDefault();
  }

  void _handleFocusLost(BlockContent content) {
    final platform = SocialPlatform.fromMap({
      'id': content.metadata?['platformId'] ?? '',
      'value': content.url,
    });

    if (!(platform.id == 'facebook' ||
        platform.id == 'linkedin' ||
        platform.id == 'linkedin_company' ||
        platform.id == 'website' ||
        platform.id == 'address' ||
        platform.id == 'bluesky')) {
      return;
    }

    final controller = _socialControllers[content.id];
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
        case 'bluesky':
          prefix = 'bsky.app/profile/';
          break;
      }
      
      final newValue = prefix + controller.text;
      controller.text = newValue;
      _updateContent(content.copyWith(url: newValue));
    }
  }

  void _updateBlock() {
    final updatedBlock = widget.block.copyWith(
      contents: _contents,
      sequence: widget.block.sequence,
      isVisible: _isVisible,
    );
    widget.onBlockUpdated(updatedBlock);
  }

  void _addPlatform() async {
    final selectedPlatform = await showDialog<SocialPlatform>(
      context: context,
      builder: (context) => const SocialMediaSelector(selectedPlatformIds: []),
    );

    if (selectedPlatform != null) {
      final newContent = BlockContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        subtitle: '',
        url: '',
        metadata: {
          'platformId': selectedPlatform.id,
          'platformName': selectedPlatform.name,
        },
      );

      _titleControllers[newContent.id] = TextEditingController();
      _subtitleControllers[newContent.id] = TextEditingController();

      if (selectedPlatform.requiresCountryCode && selectedPlatform.numbersOnly) {
        _phoneControllers[newContent.id] = TextEditingController();
        _countryNotifiers[newContent.id] = ValueNotifier(CountryCodes.getDefault());
      } else {
        _socialControllers[newContent.id] = TextEditingController();
        _focusNodes[newContent.id] = FocusNode()
          ..addListener(() {
            if (!_focusNodes[newContent.id]!.hasFocus) {
              _handleFocusLost(newContent);
            }
          });
      }

      setState(() {
        _contents.add(newContent);
      });
      _updateBlock();
    }
  }

  void _updateContent(BlockContent updatedContent) {
    final index = _contents.indexWhere((c) => c.id == updatedContent.id);
    if (index != -1) {
      setState(() {
        _contents[index] = updatedContent;
      });
      _updateBlock();
    }
  }

  void _removePlatform(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Platform'),
        content: const Text('Are you sure you want to delete this platform?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final content = _contents[index];
              
              if (content.imageUrl != null && content.imageUrl!.isNotEmpty) {
                final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
                await provider.deleteBlockImage(widget.block.id, content.imageUrl!);
              }

              setState(() {
                _contents.removeAt(index);
              });
              _updateBlock();
            },
            child: Text('Delete', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  void _reorderPlatforms(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _contents.removeAt(oldIndex);
      _contents.insert(newIndex, item);
    });
    _updateBlock();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: _reorderPlatforms,
      children: [
        ..._contents.asMap().entries.map((entry) {
          final index = entry.key;
          final content = entry.value;
          return _PlatformCard(
            key: ValueKey(content.id),
            content: content,
            index: index,
            onUpdate: _updateContent,
            onDelete: () => _removePlatform(index),
            phoneController: _phoneControllers[content.id],
            countryNotifier: _countryNotifiers[content.id],
            socialController: _socialControllers[content.id],
            focusNode: _focusNodes[content.id],
            titleController: _titleControllers[content.id], // Pass title controller
            subtitleController: _subtitleControllers[content.id], // Pass subtitle controller
          );
        }),
        Container(
          key: const ValueKey('add-platform'),
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: ElevatedButton(
            onPressed: _addPlatform,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
              foregroundColor: isDarkMode ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
                  'Add Platform',
                  style: TextStyle(
                    color: isDarkMode ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _phoneControllers.values) {
      controller.dispose();
    }
    for (var controller in _socialControllers.values) {
      controller.dispose();
    }
     for (var controller in _titleControllers.values) {
      controller.dispose();
    }
    for (var controller in _subtitleControllers.values) {
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
}

class _PlatformCard extends StatelessWidget {
  final BlockContent content;
  final int index;
  final Function(BlockContent) onUpdate;
  final VoidCallback onDelete;
  final TextEditingController? phoneController;
  final ValueNotifier<CountryCode>? countryNotifier;
  final TextEditingController? socialController;
  final FocusNode? focusNode;
  final TextEditingController? titleController; // Added title controller
  final TextEditingController? subtitleController; // Added subtitle controller

  const _PlatformCard({
    super.key,
    required this.content,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
    this.phoneController,
    this.countryNotifier,
    this.socialController,
    this.focusNode,
    this.titleController, // Added title controller
    this.subtitleController, // Added subtitle controller
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final platform = SocialPlatform.fromMap({
      'id': content.metadata?['platformId'] ?? '',
      'value': content.url,
    });

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.black12,
        ),
      ),
       child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_indicator),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Title',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                        ),
                      ),
                      fillColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    onChanged: (value) {
                      onUpdate(content.copyWith(title: value));
                    },
                  ),
                  const SizedBox(height: 8),
                   TextFormField( // Subtitle field
                    controller: subtitleController,
                    decoration: InputDecoration(
                      hintText: 'Subtitle',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                        ),
                      ),
                      fillColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                     onChanged: (value) {
                      onUpdate(content.copyWith(subtitle: value));
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(platform.icon),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPlatformInput(platform), // Existing platform-specific input
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              LinkImageUpload(
                currentImageUrl: content.imageUrl,
                linkId: content.id,
                onImageUploaded: (url) => onUpdate(content.copyWith(imageUrl: url)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: content.isVisible,
                      onChanged: (value) => onUpdate(content.copyWith(isVisible: value)),
                      activeColor: isDarkMode ? Colors.white : Colors.black,
                      activeTrackColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
                      inactiveThumbColor: isDarkMode ? Colors.white : Colors.black,
                      inactiveTrackColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
                      trackOutlineColor: WidgetStateProperty.all(
                        isDarkMode ? Colors.white : Colors.black,
                      ),
                      trackOutlineWidth: WidgetStateProperty.all(1.5),
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: const [
                            Icon(Icons.analytics_outlined),
                            SizedBox(width: 8),
                            Text('Analytics'),
                          ],
                        ),
                        onTap: () {
                          // Analytics functionality
                        },
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: const [
                            Icon(Icons.animation),
                            SizedBox(width: 8),
                            Text('Animation'),
                          ],
                        ),
                        onTap: () {
                          // Animation settings
                        },
                      ),
                      PopupMenuItem(
                        onTap: onDelete,
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red[700])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformInput(SocialPlatform platform) {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        if (platform.requiresCountryCode && platform.numbersOnly) {
          return Row(
            children: [
              const SizedBox(width: 8),
              ValueListenableBuilder<CountryCode>(
                valueListenable: countryNotifier!,
                builder: (context, country, _) => InkWell(
                  onTap: () async {
                    final selected = await showDialog<CountryCode>(
                      context: context,
                      builder: (context) => const CountrySearchDialog(),
                    );
                    if (selected != null) {
                      countryNotifier!.value = selected;
                    }
                  },
                  child: country.getFlagWidget(width: 24, height: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    hintText: platform.placeholder,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                      ),
                    ),
                    fillColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    prefixText: phoneController!.text.isNotEmpty ? '${countryNotifier!.value.dialCode} ' : null,
                  ),
                  onChanged: (value) {
                    final formattedNumber = value.startsWith('0') ? value.substring(1) : value;
                    final fullNumber = '${countryNotifier!.value.dialCode}$formattedNumber';
                    onUpdate(content.copyWith(url: fullNumber));
                  },
                ),
              ),
            ],
          );
        }
        
        return TextFormField(
          controller: socialController,
          decoration: InputDecoration(
            hintText: platform.placeholder,
            prefix: platform.prefix != null ? Text(platform.prefix!) : null,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDarkMode ? const Color(0xFF121212) : Colors.white,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDarkMode ? const Color(0xFF121212) : Colors.white,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDarkMode ? const Color(0xFF121212) : Colors.white,
              ),
            ),
            fillColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
          ),
          onChanged: (value) {
            final parsedValue = platform.parseUrl(value);
            onUpdate(content.copyWith(url: parsedValue));
          },
        );
      }
    );
  }
}