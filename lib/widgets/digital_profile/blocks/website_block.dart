// lib/widgets/digital_profile/blocks/website_block.dart
// Widget for managing website link collections. Features title, subtitle, and URL inputs, thumbnail image upload, visibility toggle, and analytics integration.
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'link_image_upload.dart';
import '../../../models/block.dart';
import '../../../providers/digital_profile_provider.dart';

class WebsiteBlock extends StatefulWidget {
  final Block block;
  final Function(Block) onBlockUpdated;
  final Function(String) onBlockDeleted;

  const WebsiteBlock({
    super.key,
    required this.block,
    required this.onBlockUpdated,
    required this.onBlockDeleted,
  });

  @override
  State<WebsiteBlock> createState() => _WebsiteBlockState();
}

class _WebsiteBlockState extends State<WebsiteBlock> {
  late List<BlockContent> _contents;
  late bool _isVisible;

  @override
  void initState() {
    super.initState();
    _contents = List.from(widget.block.contents);
    _isVisible = widget.block.isVisible ?? true;
  }

  void _updateBlock() {
    final updatedBlock = widget.block.copyWith(
      contents: _contents,
      sequence: widget.block.sequence,
      isVisible: _isVisible,
    );
    widget.onBlockUpdated(updatedBlock);
  }

  void _addLink() {
    setState(() {
      _contents.add(BlockContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        url: '',
        isVisible: true,
      ));
    });
    _updateBlock();
  }

  void _updateLink(int index, BlockContent updatedContent) {
    setState(() {
      _contents[index] = updatedContent;
    });
    _updateBlock();
  }

  void _removeLink(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Link'),
        content: const Text(
            'Are you sure you want to delete this link? All associated analytics will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Delete image from storage if exists
              final content = _contents[index];
              if (content.imageUrl != null && content.imageUrl!.isNotEmpty) {
                final provider =
                    Provider.of<DigitalProfileProvider>(context, listen: false);
                await provider.deleteBlockImage(
                    widget.block.id, content.imageUrl!);
              }

              setState(() {
                _contents.removeAt(index);
              });
              _updateBlock();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _reorderLinks(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
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
      onReorder: _reorderLinks,
      children: [
        ..._contents.asMap().entries.map((entry) {
          final index = entry.key;
          final content = entry.value;
          return _LinkCard(
            key: ValueKey(content.id),
            content: content,
            index: index,
            onUpdate: (updated) => _updateLink(index, updated),
            onDelete: () => _removeLink(index),
          );
        }),
        Container(
          key: const ValueKey('add-link'),
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: ElevatedButton(
            onPressed: _addLink,
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
                  'Add Link',
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
}

class _LinkCard extends StatefulWidget {
  final BlockContent content;
  final Function(BlockContent) onUpdate;
  final VoidCallback onDelete;
  final int index;

  const _LinkCard({
    super.key,
    required this.content,
    required this.onUpdate,
    required this.onDelete,
    required this.index,
  });

  @override
  State<_LinkCard> createState() => _LinkCardState();
}

class _LinkCardState extends State<_LinkCard> {
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _subtitleFocus = FocusNode();
  final FocusNode _urlFocus = FocusNode();

  @override
  void dispose() {
    _titleFocus.dispose();
    _subtitleFocus.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ReorderableDragStartListener(
              index: widget.index,
              child: GestureDetector(
                onTapDown: (_) {
                  _titleFocus.unfocus();
                  _subtitleFocus.unfocus();
                  _urlFocus.unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.gripVertical, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    focusNode: _titleFocus,
                    initialValue: widget.content.title,
                    decoration: InputDecoration(
                      hintText: 'Title (required)',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? const Color(0xFF121212)
                              : Colors.white,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? const Color(0xFF121212)
                              : Colors.white,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? const Color(0xFF121212)
                              : Colors.white,
                        ),
                      ),
                      fillColor:
                          isDarkMode ? const Color(0xFF121212) : Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    onChanged: (value) =>
                        widget.onUpdate(widget.content.copyWith(title: value)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    focusNode: _subtitleFocus,
                    initialValue: widget.content.subtitle,
                    decoration: InputDecoration(
                      hintText: 'Subtitle (optional)',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? const Color(0xFF121212)
                              : Colors.white,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? const Color(0xFF121212)
                              : Colors.white,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? const Color(0xFF121212)
                              : Colors.white,
                        ),
                      ),
                      fillColor:
                          isDarkMode ? const Color(0xFF121212) : Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    onChanged: (value) => widget.onUpdate(
                        widget.content.copyWith(subtitle: value)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.link, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          focusNode: _urlFocus,
                          initialValue: widget.content.url,
                          decoration: InputDecoration(
                            hintText: 'example.com',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? const Color(0xFF121212)
                                    : Colors.white,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? const Color(0xFF121212)
                                    : Colors.white,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? const Color(0xFF121212)
                                    : Colors.white,
                              ),
                            ),
                            fillColor: isDarkMode
                                ? const Color(0xFF121212)
                                : Colors.white,
                            filled: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8.0),
                          ),
                          onChanged: (value) =>
                              widget.onUpdate(widget.content.copyWith(url: value)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                LinkImageUpload(
                  currentImageUrl: widget.content.imageUrl,
                  linkId: widget.content.id,
                  onImageUploaded: (url) =>
                      widget.onUpdate(widget.content.copyWith(imageUrl: url)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: widget.content.isVisible,
                        onChanged: (value) => widget.onUpdate(
                            widget.content.copyWith(isVisible: value)),
                        activeColor: isDarkMode ? Colors.white : Colors.black,
                        activeTrackColor:
                            isDarkMode ? const Color(0xFF121212) : Colors.white,
                        inactiveThumbColor:
                            isDarkMode ? Colors.white : Colors.black,
                        inactiveTrackColor:
                            isDarkMode ? const Color(0xFF121212) : Colors.white,
                        trackOutlineColor: WidgetStateProperty.all(
                          isDarkMode ? Colors.white : Colors.black,
                        ),
                        trackOutlineWidth: WidgetStateProperty.all(1.5),
                      ),
                    ),
                    PopupMenuButton(
                      position: PopupMenuPosition.under,
                      offset: const Offset(0, 0),
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
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Coming Soon!'),
                                  content: const Text(
                                      'Analytics feature will be available in future updates. Stay tuned!'),
                                  actions: [
                                    TextButton(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                            });
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
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Coming Soon!'),
                                  content: const Text(
                                      'Animation settings will be available in future updates. Stay tuned!'),
                                  actions: [
                                    TextButton(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              );
                            });
                          },
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red[700])),
                            ],
                          ),
                          onTap: () {
                            widget.onDelete();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}