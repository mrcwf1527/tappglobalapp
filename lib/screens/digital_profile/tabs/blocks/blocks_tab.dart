// lib/screens/digital_profile/tabs/blocks/blocks_tab.dart
// Main interface for managing content blocks. Implements reorderable list of blocks with drag-and-drop functionality. Handles block creation, visibility toggling, editing, and deletion. Uses DigitalProfileProvider for state management.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../models/block.dart';
import '../../../../providers/digital_profile_provider.dart';
import '../../../../widgets/selectors/blocks_selector.dart';

class BlocksTab extends StatelessWidget {
  const BlocksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<DigitalProfileProvider>(
      builder: (context, provider, _) => ReorderableListView(
        padding: const EdgeInsets.all(16),
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) {
          final blocks = [...provider.profileData.blocks];
          if (oldIndex < newIndex) newIndex -= 1;
          final item = blocks.removeAt(oldIndex);
          blocks.insert(newIndex, item);
          
          // Update sequence numbers
          for (var i = 0; i < blocks.length; i++) {
            blocks[i] = blocks[i].copyWith(sequence: i + 1);
          }
          
          provider.updateBlocks(blocks);
        },
        footer: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ElevatedButton(
            onPressed: () async {
              final selectedType = await showDialog<BlockType>(
                context: context,
                builder: (context) => const BlocksSelector(),
              );

              if (selectedType != null) {
                final newBlock = createNewBlock(selectedType, provider.profileData.blocks.length + 1);
                provider.updateBlocks([...provider.profileData.blocks, newBlock]);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
              foregroundColor: isDarkMode ? Colors.black : Colors.white,
              minimumSize: const Size(double.infinity, 50),
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
                const Text('Add Block'),
              ],
            ),
          ),
        ),
        children: provider.profileData.blocks.asMap().entries.map((entry) {
          final block = entry.value;
          return InkWell(
            key: ValueKey(block.id),
            onTap: () => _navigateToEditBlock(context, block),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF121212) : Colors.white,
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF232323) : const Color(0xFFA9A9A9),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: entry.key,
                      child: const Icon(Icons.drag_indicator),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _getBlockIcon(block.type),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        block.blockName.isEmpty ? _getBlockTitle(block.type) : block.blockName,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.6,
                      child: SizedBox(
                        width: 60,
                        height: 30,
                        child: Switch(
                          value: block.isVisible ?? true,
                          activeColor: isDarkMode ? Colors.white : Colors.black,
                          activeTrackColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
                          inactiveThumbColor: isDarkMode ? Colors.white : Colors.black,
                          inactiveTrackColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
                          trackOutlineColor: WidgetStateProperty.all(
                            isDarkMode ? Colors.white : Colors.black,
                          ),
                          trackOutlineWidth: WidgetStateProperty.all(1.5),
                          onChanged: (value) {
                            final blocks = [...provider.profileData.blocks];
                            blocks[entry.key] = block.copyWith(
                              isVisible: value,
                              sequence: block.sequence,
                            );
                            provider.updateBlocks(blocks);
                          },
                        ),
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () => _navigateToEditBlock(context, block),
                          child: Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.pen, size: 16),
                              const SizedBox(width: 8),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => _showDeleteConfirmation(
                            context,
                            block,
                            () {
                              final blocks = [...provider.profileData.blocks];
                              blocks.removeAt(entry.key);
                              provider.updateBlocks(blocks);
                            }
                          ),
                          child: Row(
                            children: [
                              FaIcon(FontAwesomeIcons.trash, 
                                size: 16, 
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 8),
                              Text('Delete',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Block block, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Block'),
        content: const Text('Are you sure you want to delete this block?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
          
              // Handle storage cleanup based on block type
              switch (block.type) {
                case BlockType.website:
                case BlockType.image:
                  // Use deleteAllBlockImages for both website and image blocks
                  await provider.deleteAllBlockImages(
                    block.id,
                    block.type,
                    block.contents
                  );
                  break;
                case BlockType.contact:
                  await provider.deleteBlockStorage(block.id);
                  break;
                default:
                  break;
              }
          
              onConfirm();
            },
            child: Text('Delete',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBlockIcon(BlockType type) {
    switch (type) {
      case BlockType.website:
        return FontAwesomeIcons.link;
      case BlockType.image:
        return FontAwesomeIcons.image;
      case BlockType.youtube:
        return FontAwesomeIcons.youtube;
      case BlockType.contact:
        return FontAwesomeIcons.addressBook;
      case BlockType.text:
        return FontAwesomeIcons.font;
      case BlockType.spacer:
        return FontAwesomeIcons.minus;
      case BlockType.socialPlatform:
        return FontAwesomeIcons.layerGroup;
    }
  }

  String _getBlockTitle(BlockType type) {
    switch (type) {
      case BlockType.website:
        return 'Website Links';
      case BlockType.image:
        return 'Image Gallery';
      case BlockType.youtube:
        return 'YouTube Videos';
      case BlockType.contact:
        return 'Contact Card';
      case BlockType.text:
        return 'Text';
      case BlockType.spacer:
        return 'Space & Dividers';
      case BlockType.socialPlatform:
        return 'Social Platforms';
    }
  }

  void _navigateToEditBlock(BuildContext context, Block block) {
    Navigator.pushNamed(
      context,
      '/edit-block',
      arguments: block,
    );
  }

   Block createNewBlock(BlockType type, int sequence) {
    switch (type) {
      case BlockType.website:
        return Block(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          blockName: '',
          title: '',
          description: '',
          contents: [],
          sequence: sequence,
          isVisible: true,
          textAlignment: TextAlignment.center,
        );
        
      case BlockType.image:
        return Block(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          blockName: '',
          title: '',
          description: '',
          contents: [],
          sequence: sequence,
          isVisible: true,
          aspectRatio: '16:9',
        );
        
      case BlockType.youtube:
        return Block(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          blockName: '',
          title: '',
          description: '',
          contents: [],
          sequence: sequence,
          isVisible: true,
        );
      case BlockType.contact:
        return Block(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          blockName: '',
          title: '',
          description: '',
          contents: [
            BlockContent(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: '',
              url: '',
              metadata: {
                'phones': [],
                'emails': [],
              }
            )
          ],
          sequence: sequence,
          isVisible: true,
        );
      case BlockType.text:
        return Block(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          blockName: '',
          title: '',
          description: '',
          contents: [],
          sequence: sequence,
          isVisible: true,
          textAlignment: TextAlignment.left,
        );
      case BlockType.spacer:
        return Block(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          blockName: '',
          title: '',
          description: '',
          contents: [
            BlockContent(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: '',
              url: '',
              metadata: {
                'height': 16.0,
                'dividerStyle': 'none',
              },
            )
          ],
          sequence: sequence,
          isVisible: true,
        );
      case BlockType.socialPlatform:
        return Block(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          blockName: '',
          title: '',
          description: '',
          contents: [],
          sequence: sequence,
          isVisible: true,
          textAlignment: TextAlignment.center,
        );
    }
  }
}