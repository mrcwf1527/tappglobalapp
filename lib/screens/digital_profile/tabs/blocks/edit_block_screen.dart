// lib/screens/digital_profile/tabs/blocks/edit_block_screen.dart
// Detailed block editing interface with three tabs (Links, Layouts, Settings). Manages block properties, content arrangement, layout options, and visibility settings. Includes specialized editors for different block types.
import 'package:flutter/material.dart';
import '../../../../models/block.dart';
import '../../../../utils/debouncer.dart';
import '../../../../widgets/digital_profile/blocks/contact_block.dart';
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
  late List<BlockContent> _contents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _blockNameController.text = widget.block.blockName;
    _contents = List.from(widget.block.contents);
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    _blockNameController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EditBlockScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.contents != widget.block.contents) {
      setState(() {
        _contents = List.from(widget.block.contents);
      });
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
        return 'Contact Details';
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
      case BlockType.contact:
        return Icons.contact_mail;
    }
  }

  void _showDeleteConfirmation(BuildContext context, VoidCallback onConfirm) {
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
              final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
            
              // Get the latest block state from provider
              final currentBlock = provider.profileData.blocks
                  .firstWhere((b) => b.id == widget.block.id);
            
              // Delete images based on current block state
              switch (currentBlock.type) {
                case BlockType.website:
                case BlockType.image:
                  await provider.deleteAllBlockImages(
                    currentBlock.id, 
                    currentBlock.type,
                    currentBlock.contents
                  );
                  break;
                case BlockType.contact:
                  await provider.deleteBlockStorage(currentBlock.id);
                  break;
                default:
                  break;
              }
            
              setState(() => _isDeleted = true);
              onConfirm();
              Navigator.pop(context);
            },
            child: Text('Delete',
              style: TextStyle(color: Colors.red[700]),
            ),
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
                                    b.copyWith(
                                      blockName: value,
                                      sequence: b.sequence,
                                    )
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
                    Consumer<DigitalProfileProvider>(
                      builder: (context, provider, _) {
                        final currentBlock = provider.profileData.blocks
                            .firstWhere((b) => b.id == widget.block.id);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: SingleChildScrollView(
                            child: _buildEditor(
                              provider.profileData.blocks.indexOf(currentBlock),
                              provider,
                            ),
                          ),
                        );
                      },
                    ),
                    // Layouts Tab
                    Consumer<DigitalProfileProvider>(
                      builder: (context, provider, _) => _LayoutsTab(
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
                        block: provider.profileData.blocks
                            .firstWhere((b) => b.id == widget.block.id),
                      ),
                    ),
                    // Settings Tab
                    Consumer<DigitalProfileProvider>(
                      builder: (context, provider, _) => _SettingsTab(
                        block: provider.profileData.blocks
                            .firstWhere((b) => b.id == widget.block.id),
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 56),
            ],
          );
        },
      ),
    ),
    );
  }
  
  Widget _buildEditor(int blockIndex, DigitalProfileProvider provider) {
    final currentBlock = provider.profileData.blocks
        .firstWhere((b) => b.id == widget.block.id);

    Widget blockEditor;
    switch (currentBlock.type) {
      case BlockType.website:
        blockEditor = WebsiteBlock(
          block: currentBlock,
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
          block: currentBlock,
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
          block: currentBlock,
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
      case BlockType.contact:
        blockEditor = ContactBlock(
          block: currentBlock,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final containerSize = 32.0;

    return Container(
      width: containerSize,
      height: containerSize,  // Fixed height
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final width = ratio >= 1 ? maxWidth : maxWidth * ratio;
          final height = ratio >= 1 ? maxWidth / ratio : maxWidth;
        
          return Center(
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAspectRatioModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.background, // Dark in dark mode
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
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
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildAspectRatioIcon(option.ratio),
                    const SizedBox(width: 12),
                    Text(
                      option.label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const Spacer(),
                    if (selectedAspectRatio == option.value)
                      Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            )).toList(),
          ),
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
          if (widget.block.type == BlockType.contact) ...[
            // Contact block layouts
            Column(
              children: [
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
                        title: 'BUSINESS CARD',
                        icon: Icons.credit_card,
                        isSelected: selectedLayout == BlockLayout.businessCard,
                        onTap: () => setState(() {
                          selectedLayout = BlockLayout.businessCard;
                          widget.onLayoutChanged(BlockLayout.businessCard, null);
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _LayoutOption(
                        title: 'ICON BUTTON',
                        icon: Icons.smart_button,
                        isSelected: selectedLayout == BlockLayout.iconButton,
                        onTap: () => setState(() {
                          selectedLayout = BlockLayout.iconButton;
                          widget.onLayoutChanged(BlockLayout.iconButton, null);
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _LayoutOption(
                        title: 'QR CODE',
                        icon: Icons.qr_code,
                        isSelected: selectedLayout == BlockLayout.qrCode,
                        onTap: () => setState(() {
                          selectedLayout = BlockLayout.qrCode;
                          widget.onLayoutChanged(BlockLayout.qrCode, null);
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            // Original layout options for other block types
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
                        border: Border.all(
                          color: Colors.grey.shade600,  // Same as unselected layout
                          width: 1,  // Same as unselected layout
                        ),
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
  final _titleDebouncer = Debouncer();
  final _descriptionDebouncer = Debouncer();

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
    _titleDebouncer.dispose();
    _descriptionDebouncer.dispose(); 
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
              _titleDebouncer.run(() {
                final updatedBlock = {...provider.profileData.blocks[blockIndex].toMap()};
                updatedBlock['title'] = value;
                widget.onUpdate(Block.fromMap(updatedBlock));
              });
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
              _descriptionDebouncer.run(() {
                final updatedBlock = {...provider.profileData.blocks[blockIndex].toMap()};
                updatedBlock['description'] = value;
                widget.onUpdate(Block.fromMap(updatedBlock));
              });
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
            color: isSelected 
              ? Theme.of(context).colorScheme.onBackground  // White in dark mode
              : Colors.grey.shade600,  // Darker grey in dark mode
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected 
                ? Theme.of(context).colorScheme.onBackground  // White in dark mode
                : Colors.grey.shade600,  // Darker grey in dark mode
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                  ? Theme.of(context).colorScheme.onBackground  // White in dark mode
                  : Colors.grey.shade600,  // Darker grey in dark mode
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode 
              ? (isSelected ? Colors.white : Colors.grey.shade600)
              : (isSelected ? Colors.black : Colors.grey.shade600),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isDarkMode
            ? (isSelected ? Colors.white : Colors.transparent)
            : (isSelected ? Colors.black : Colors.transparent),
        ),
        child: Icon(
          icon,
          color: isDarkMode
            ? (isSelected ? Color(0xFF121212) : Colors.grey.shade600)
            : (isSelected ? Colors.white : Colors.black),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode
              ? (isSelected ? Colors.white : Colors.grey.shade600)
              : (isSelected ? Colors.black : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDarkMode
                    ? Colors.grey.shade600
                    : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDarkMode
                  ? (isSelected ? Colors.white : Colors.grey.shade600)
                  : (isSelected ? Colors.black : Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isDarkMode
                  ? (isSelected ? Colors.white : Colors.grey.shade600)
                  : (isSelected ? Colors.black : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}