// lib/screens/digital_profile/tabs/blocks/edit_block_screen.dart
// Detailed block editing interface with three tabs (Links, Layouts, Settings). Manages block properties, content arrangement, layout options, and visibility settings. Includes specialized editors for different block types.
import 'package:flutter/material.dart';
import '../../../../models/block.dart';
import '../../../../utils/debouncer.dart';
import '../../../../widgets/digital_profile/blocks/website_block.dart';
import '../../../../widgets/digital_profile/blocks/image_block.dart';
import '../../../../widgets/digital_profile/blocks/youtube_block.dart';
import 'package:provider/provider.dart';
import '../../../../providers/digital_profile_provider.dart';

class EditBlockScreen extends StatefulWidget {
  final Block block;

  const EditBlockScreen({super.key, required this.block});

  @override
  State<EditBlockScreen> createState() => _EditBlockScreenState();
}

class _EditBlockScreenState extends State<EditBlockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _blockNameController = TextEditingController();
  final _debouncer = Debouncer();
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _blockNameController.text = widget.block.blockName;
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    _blockNameController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

    String _getBlockTitle(BlockType type) {
    switch (type) {
      case BlockType.website:
        return 'Website Links';
      case BlockType.image:
        return 'Image Gallery';
      case BlockType.youtube:
        return 'YouTube Videos';
    }
  }

  IconData _getBlockIcon(BlockType type) {
    switch (type) {
      case BlockType.website:
        return Icons.link;
      case BlockType.image:
        return Icons.image;
      case BlockType.youtube:
        return Icons.play_circle_filled;
    }
  }

  void _showDeleteConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Block"),
        content: const Text("Are you sure you want to delete this block?"),
        actions: <Widget>[
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() => _isDeleted = true);
              onConfirm();
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Scaffold(
      appBar: AppBar(
        title: Text('Edit ${_getBlockTitle(widget.block.type)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<DigitalProfileProvider>(
        builder: (context, provider, _) {
          final blockIndex = provider.profileData.blocks
              .indexWhere((b) => b.id == widget.block.id);

          if (blockIndex == -1 || _isDeleted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            });
            return const SizedBox();
          }

          return Column(
            children: [
              // Block Name & Controls
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Block Icon
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                       child: Icon(
                          _getBlockIcon(widget.block.type),
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                    ),
                    // Title TextField
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: TextField(
                          controller: _blockNameController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Block Name',
                          ),
                          onChanged: (value) {
                            _debouncer.run(() {
                              provider.updateBlocks([
                                for (var b in provider.profileData.blocks)
                                  if (b.id == widget.block.id)
                                    Block.fromMap({...b.toMap(), 'blockName': value})
                                  else
                                    b
                              ]);
                            });
                          },
                        ),
                      ),
                    ),
                    // Visibility Toggle
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: provider.profileData.blocks
                            .firstWhere((b) => b.id == widget.block.id)
                            .isVisible ?? true,
                        onChanged: (value) {
                          provider.updateBlocks([
                              for (var b in provider.profileData.blocks)
                                if (b.id == widget.block.id)
                                  b.copyWith(
                                    isVisible: value,
                                    sequence: b.sequence,
                                  )
                                else
                                  b
                            ]);
                        },
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
                    // Delete Icon
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _showDeleteConfirmation(context, () {
                        final blocks = [...provider.profileData.blocks];
                        blocks.removeAt(blockIndex);
                        provider.updateBlocks(blocks);
                      }),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Links'),
                  Tab(text: 'Layouts'),
                  Tab(text: 'Settings'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Links Tab
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                       child: SingleChildScrollView(
                        child: _buildEditor(blockIndex, provider),
                      ),
                    ),
                    // Layouts Tab
                   _LayoutsTab(
                      onLayoutChanged: (layout, aspectRatio) {
                         provider.updateBlocks([
                            for (var b in provider.profileData.blocks)
                            if (b.id == widget.block.id)
                                b.copyWith(
                                layout: layout,
                                aspectRatio: aspectRatio,
                                sequence: b.sequence,
                                )
                            else
                                b
                            ]);
                      },
                      block: widget.block,
                    ),
                    // Settings Tab
                    _SettingsTab(
                      block: widget.block,
                       onUpdate: (updated) {
                          provider.updateBlocks([
                            for (var b in provider.profileData.blocks)
                              if (b.id == widget.block.id)
                                updated
                              else
                                b
                          ]);
                        },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
  
  Widget _buildEditor(int blockIndex, DigitalProfileProvider provider) {
    Widget blockEditor;
    switch (widget.block.type) {
      case BlockType.website:
        blockEditor = WebsiteBlock(
          block: widget.block,
          onBlockUpdated: (updated) {
            final blocks = [...provider.profileData.blocks];
            blocks[blockIndex] = updated;
            provider.updateBlocks(blocks);
          },
          onBlockDeleted: (id) {
            final blocks = [...provider.profileData.blocks];
            blocks.removeAt(blockIndex);
            provider.updateBlocks(blocks);
            Navigator.maybePop(context);
          },
        );
      case BlockType.image:
        blockEditor = ImageBlock(
          block: widget.block,
          onBlockUpdated: (updated) {
            final blocks = [...provider.profileData.blocks];
            blocks[blockIndex] = updated;
            provider.updateBlocks(blocks);
          },
          onBlockDeleted: (id) {
            final blocks = [...provider.profileData.blocks];
            blocks.removeAt(blockIndex);
            provider.updateBlocks(blocks);
            Navigator.maybePop(context);
          },
        );
      case BlockType.youtube:
        blockEditor = YouTubeBlock(
          block: widget.block,
          onBlockUpdated: (updated) {
            final blocks = [...provider.profileData.blocks];
            blocks[blockIndex] = updated;
            provider.updateBlocks(blocks);
          },
          onBlockDeleted: (id) {
            final blocks = [...provider.profileData.blocks];
            blocks.removeAt(blockIndex);
            provider.updateBlocks(blocks);
            Navigator.maybePop(context);
          },
        );
    }
    return blockEditor;
  }
}

class AspectRatioOption {
  final String value;
  final String label;
  final double ratio;

  const AspectRatioOption({
    required this.value,
    required this.label,
    required this.ratio,
  });
}

class _LayoutsTab extends StatefulWidget {
  final Function(BlockLayout, String?) onLayoutChanged;
  final Block block;

  const _LayoutsTab({
    required this.onLayoutChanged,
    required this.block,
  });

  @override
  State<_LayoutsTab> createState() => _LayoutsTabState();
}

class _LayoutsTabState extends State<_LayoutsTab> {
  BlockLayout selectedLayout = BlockLayout.classic;
  String selectedAspectRatio = '16:9';
  TextAlign selectedAlignment = TextAlign.center;
  
  @override
  void initState() {
    super.initState();
    selectedLayout = widget.block.layout;
    selectedAspectRatio = widget.block.aspectRatio ?? '16:9';
  }
  
  final List<AspectRatioOption> aspectRatios = const [
    AspectRatioOption(value: '1:1', label: '1:1 Square', ratio: 1),
    AspectRatioOption(value: '3:2', label: '3:2 Horizontal', ratio: 1.5),
    AspectRatioOption(value: '16:9', label: '16:9 Horizontal', ratio: 1.77),
    AspectRatioOption(value: '3:1', label: '3:1 Horizontal', ratio: 3),
    AspectRatioOption(value: '2:3', label: '2:3 Vertical', ratio: 0.66),
  ];

  Widget _buildAspectRatioIcon(double ratio) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: AspectRatio(
        aspectRatio: ratio,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  void _showAspectRatioModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: aspectRatios.map((option) => InkWell(
            onTap: () {
              setState(() {
                selectedAspectRatio = option.value;
              });
              widget.onLayoutChanged(selectedLayout, option.value);
              Navigator.pop(context);
            },
            child: Container(
              color: selectedAspectRatio == option.value 
                ? Colors.blue.withAlpha((0.1 * 255).toInt())
                : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildAspectRatioIcon(option.ratio),
                  const SizedBox(width: 12),
                  Text(option.label),
                  const Spacer(),
                  if (selectedAspectRatio == option.value)
                    const Icon(Icons.check, color: Colors.blue),
                ],
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  void _updateTextAlignment(TextAlignment alignment) {
    final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
    provider.updateBlocks([
      for (var b in provider.profileData.blocks)
        if (b.id == widget.block.id)
          b.copyWith(
            textAlignment: alignment,
            sequence: b.sequence,
          )
        else
          b
    ]);
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _LayoutOption(
                  title: 'CLASSIC',
                  icon: Icons.view_agenda,
                  isSelected: selectedLayout == BlockLayout.classic,
                  onTap: () => setState(() {
                    selectedLayout = BlockLayout.classic;
                    widget.onLayoutChanged(BlockLayout.classic, null);
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LayoutOption(
                  title: 'CAROUSEL',
                  icon: Icons.view_carousel,
                  isSelected: selectedLayout == BlockLayout.carousel,
                  onTap: () => setState(() {
                    selectedLayout = BlockLayout.carousel;
                    widget.onLayoutChanged(BlockLayout.carousel, selectedAspectRatio);
                  }),
                ),
              ),
            ],
          ),
          
          // Show aspect ratio only for image blocks in carousel layout
          if (widget.block.type == BlockType.image && selectedLayout == BlockLayout.carousel) ...[
            const SizedBox(height: 24),
             Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aspect Ratio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _showAspectRatioModal(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildAspectRatioIcon(
                          aspectRatios.firstWhere((opt) => opt.value == selectedAspectRatio).ratio
                        ),
                        const SizedBox(width: 12),
                        Text(aspectRatios.firstWhere((opt) => opt.value == selectedAspectRatio).label),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Show text alignment only for website blocks
          if (widget.block.type == BlockType.website) ...[
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Text alignment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _AlignmentOption(
                      icon: Icons.format_align_left,
                      isSelected: selectedAlignment == TextAlign.left,
                      onTap: () {
                         setState(() => selectedAlignment = TextAlign.left);
                        _updateTextAlignment(TextAlignment.left);
                      },
                    ),
                    const SizedBox(width: 8),
                    _AlignmentOption(
                      icon: Icons.format_align_center,
                      isSelected: selectedAlignment == TextAlign.center,
                      onTap: () {
                        setState(() => selectedAlignment = TextAlign.center);
                         _updateTextAlignment(TextAlignment.center);
                      },
                    ),
                    const SizedBox(width: 8),
                    _AlignmentOption(
                      icon: Icons.format_align_right,
                      isSelected: selectedAlignment == TextAlign.right,
                      onTap: () {
                        setState(() => selectedAlignment = TextAlign.right);
                        _updateTextAlignment(TextAlignment.right);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  final Block block;
  final Function(Block) onUpdate;

  const _SettingsTab({
    required this.block,
    required this.onUpdate,
  });

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
  
}

class _SettingsTabState extends State<_SettingsTab> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.block.title);
    _descriptionController = TextEditingController(text: widget.block.description);
    _isCollapsed = widget.block.isCollapsed ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
    final blockIndex = provider.profileData.blocks
              .indexWhere((b) => b.id == widget.block.id);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Title (optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help your audience find the link they\'re looking for by adding a title and description to this links block.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
                final updatedBlock = {...provider.profileData.blocks[blockIndex].toMap()};
                updatedBlock['title'] = value;
                widget.onUpdate(Block.fromMap(updatedBlock));
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Description',
              border: OutlineInputBorder(),
            ),
             onChanged: (value) {
                final updatedBlock = {...provider.profileData.blocks[blockIndex].toMap()};
                updatedBlock['description'] = value;
                widget.onUpdate(Block.fromMap(updatedBlock));
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Links block visibility',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _VisibilityOption(
                  title: 'EXPOSED',
                  icon: Icons.view_agenda,
                  isSelected: !_isCollapsed,
                  onTap: () {
                    setState(() {
                      _isCollapsed = false;
                    });
                    final updatedBlock = widget.block.copyWith(
                      isCollapsed: false,
                      sequence: widget.block.sequence,
                    );
                    widget.onUpdate(updatedBlock);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VisibilityOption(
                  title: 'COLLAPSED',
                  icon: Icons.view_headline,
                  isSelected: _isCollapsed,
                  onTap: () {
                    setState(() {
                      _isCollapsed = true;
                    });
                    final updatedBlock = widget.block.copyWith(
                      isCollapsed: true,
                      sequence: widget.block.sequence,
                    );
                    widget.onUpdate(updatedBlock);
                  }
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LayoutOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LayoutOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.black : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlignmentOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlignmentOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.black : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}