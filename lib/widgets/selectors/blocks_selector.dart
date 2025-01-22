// lib/widgets/selectors/blocks_selector.dart
// Dialog widget for selecting content block types. Shows options for Website Links, Image Gallery, and YouTube Videos with icons and descriptions. Supports both light/dark themes and returns selected BlockType to parent widget. Used when adding new blocks to digital profiles.
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/block.dart';
import '../../providers/digital_profile_provider.dart';

class BlocksSelector extends StatelessWidget {
  const BlocksSelector({super.key});

  static final List<Map<String, dynamic>> _blockTypes = [
    {
      'type': BlockType.website,
      'name': 'Website Links',
      'icon': FontAwesomeIcons.link,
      'description': 'Add clickable website links'
    },
    {
      'type': BlockType.image,
      'name': 'Image Gallery',
      'icon': FontAwesomeIcons.image,
      'description': 'Upload and display images'
    },
    {
      'type': BlockType.youtube,
      'name': 'YouTube Videos',
      'icon': FontAwesomeIcons.youtube,
      'description': 'Add embedded YouTube videos'
    },
    {
      'type': BlockType.contact,
      'name': 'Contact Details',
      'icon': FontAwesomeIcons.addressCard,
      'description': 'Add personal contact information'
    },
    {
      'type': BlockType.text,
      'name': 'Text',
      'icon': FontAwesomeIcons.font,
      'description': 'Add formatted text with different styles'
    },
    {
      'type': BlockType.spacer,
      'name': 'Space & Dividers',
      'icon': FontAwesomeIcons.minus,
      'description': 'Add spacing and decorative dividers'
    },
    {
      'type': BlockType.socialPlatform,
      'name': 'Social Platforms',
      'icon': FontAwesomeIcons.layerGroup,
      'description': 'Add multiple social media profiles'
    },
  ];

  List<Map<String, dynamic>> _getAvailableBlocks(BuildContext context) {
    final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
    final hasContactBlock = provider.profileData.blocks
        .any((block) => block.type == BlockType.contact);

    return _blockTypes.where((block) =>
        block['type'] != BlockType.contact || !hasContactBlock).toList();
  }

  Widget _buildBlockItem(Map<String, dynamic> block, bool isDarkMode, BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context, block['type']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(block['icon']),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    block['description'],
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.7;

    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Block',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: _getAvailableBlocks(context)
                        .map((block) => _buildBlockItem(block, isDarkMode, context))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}