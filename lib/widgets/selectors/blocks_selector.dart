// lib/widgets/selectors/blocks_selector.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/block.dart';

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
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
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
            ...List.generate(_blockTypes.length, (index) {
              final block = _blockTypes[index];
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
            }),
          ],
        ),
      ),
    );
  }
}