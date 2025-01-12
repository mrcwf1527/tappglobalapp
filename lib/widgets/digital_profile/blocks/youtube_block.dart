// lib/widgets/digital_profile/blocks/youtube_block.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/block.dart';
import '../../../utils/debouncer.dart';
import 'link_image_upload.dart';

class YouTubeBlock extends StatefulWidget {
  final Block block;
  final Function(Block) onBlockUpdated;
  final Function(String) onBlockDeleted;

  const YouTubeBlock({
    super.key,
    required this.block,
    required this.onBlockUpdated,
    required this.onBlockDeleted,
  });

  @override
  State<YouTubeBlock> createState() => _YouTubeBlockState();
}

class _YouTubeBlockState extends State<YouTubeBlock> {
  late List<BlockContent> _contents;
  final _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    _contents = List.from(widget.block.contents);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _updateBlock() {
    _debouncer.run(() {
      final updatedBlock = widget.block.copyWith(
        contents: _contents,
        sequence: widget.block.sequence,
      );
      widget.onBlockUpdated(updatedBlock);
    });
  }

  void _addVideo() {
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

  void _updateVideo(int index, BlockContent updatedContent) {
    setState(() {
      _contents[index] = updatedContent;
    });
    _updateBlock();
  }

  void _removeVideo(int index) {
    setState(() {
      _contents.removeAt(index);
    });
    _updateBlock();
  }

  void _reorderVideos(int oldIndex, int newIndex) {
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
    return ReorderableListView(
      key: const ValueKey('reorderable-list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: _reorderVideos,
      children: [
        ..._contents.asMap().entries.map((entry) {
          final index = entry.key;
          final content = entry.value;
          return _VideoCard(
            content: content,
            onUpdate: (updated) => _updateVideo(index, updated),
            onDelete: () => _removeVideo(index),
          );
        }),
        Container(
          key: const ValueKey('add-video'),
          margin: const EdgeInsets.only(top: 16),
          child: ElevatedButton(
            onPressed: _addVideo,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.plus, size: 16),
                const SizedBox(width: 8),
                const Text('Add Video'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final BlockContent content;
  final Function(BlockContent) onUpdate;
  final VoidCallback onDelete;

  const _VideoCard({
    required this.content,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FaIcon(FontAwesomeIcons.gripVertical, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: content.title,
                    decoration: const InputDecoration(
                      hintText: 'Video Title',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => onUpdate(content.copyWith(title: value)),
                  ),
                  TextFormField(
                    initialValue: content.subtitle,
                    decoration: const InputDecoration(
                      hintText: 'Video Description (optional)',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => onUpdate(content.copyWith(subtitle: value)),
                  ),
                  TextFormField(
                    initialValue: content.url,
                    decoration: const InputDecoration(
                      hintText: 'YouTube URL',
                      border: InputBorder.none,
                      prefixIcon: FaIcon(FontAwesomeIcons.youtube),
                    ),
                    onChanged: (value) => onUpdate(content.copyWith(url: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                LinkImageUpload(
                  currentImageUrl: content.imageUrl,
                  linkId: content.id,
                  onImageUploaded: (url) => onUpdate(content.copyWith(imageUrl: url)),
                ),
                const SizedBox(height: 8),
                Transform.scale(
                  scale: 0.8,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}