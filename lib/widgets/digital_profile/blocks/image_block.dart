// lib/widgets/digital_profile/blocks/image_block.dart
// Widget for managing image galleries. Handles image upload to Firebase Storage, displays image previews, supports reordering, and manages image visibility settings.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/block.dart';
import '../../../providers/digital_profile_provider.dart';
import '../../../services/s3_service.dart';
import '../../../utils/debouncer.dart';

class ImageBlock extends StatefulWidget {
  final Block block;
  final Function(Block) onBlockUpdated;
  final Function(String) onBlockDeleted;

  const ImageBlock({
    super.key,
    required this.block,
    required this.onBlockUpdated,
    required this.onBlockDeleted,
  });

  @override
  State<ImageBlock> createState() => _ImageBlockState();
}

class _ImageBlockState extends State<ImageBlock> {
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

  void _addImage() {
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

  void _updateImage(int index, BlockContent updatedContent) {
    setState(() {
      _contents[index] = updatedContent;
    });
    _updateBlock();
  }

  void _removeImage(int index) async {
    final provider = Provider.of<DigitalProfileProvider>(context, listen: false);
    
    if (_contents[index].imageUrl != null) {
      await provider.deleteBlockStorage(widget.block.id);
      await provider.deleteBlockImage(widget.block.id, _contents[index].imageUrl!);
    }

    setState(() {
      _contents.removeAt(index);
    });
    _updateBlock();
  }

  void _reorderImages(int oldIndex, int newIndex) {
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
      key: const ValueKey('reorderable-list'),
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: _reorderImages,
      children: [
        ..._contents.asMap().entries.map((entry) {
          final index = entry.key;
          final content = entry.value;
          return _ImageCard(
            key: ValueKey(content.id),
            content: content,
            index: index,
            onUpdate: (updated) => _updateImage(index, updated),
            onDelete: () => _removeImage(index),
          );
        }),
        Container(
          key: const ValueKey('add-image'),
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: ElevatedButton(
            onPressed: _addImage,
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
                  'Add Image',
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

class _ImageCard extends StatefulWidget {
  final BlockContent content;
  final Function(BlockContent) onUpdate;
  final VoidCallback onDelete;
  final int index;

  const _ImageCard({
    required Key key,
    required this.content,
    required this.onUpdate,
    required this.onDelete,
    required this.index,
  }) : super(key: key);

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> {
  bool _isLoading = false;
  double? _aspectRatio;
  final _s3Service = S3Service();

  @override
  void initState() {
    super.initState();
    if (widget.content.imageUrl != null) {
      _loadImageDimensions();
    }
  }

  Future<void> _loadImageDimensions() async {
    try {
      final image = Image.network(widget.content.imageUrl!);
      image.image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) {
          if (mounted) {
            setState(() {
              _aspectRatio = info.image.width / info.image.height;
            });
          }
        }),
      );
    } catch (e) {
      debugPrint('Error loading image dimensions: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      setState(() => _isLoading = true);

      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final imageBytes = await image.readAsBytes();
      final downloadUrl = await _s3Service.uploadImage(
        imageBytes: imageBytes,
        userId: userId, 
        folder: 'block_images',
        fileName: widget.content.id,
        maxSizeKB: 15360,
        maxWidth: 3840,
        maxHeight: 2160,
      );

      widget.onUpdate(widget.content.copyWith(
        imageUrl: downloadUrl,
        url: downloadUrl,
      ));

      _loadImageDimensions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          children: [
            ReorderableDragStartListener(
              index: widget.index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: FaIcon(FontAwesomeIcons.gripVertical, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.content.imageUrl != null &&
                          widget.content.imageUrl!.isNotEmpty
                      ? _buildImagePreview()
                      : _buildUploadButton(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: _pickAndUploadImage,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              'Upload Image',
              style: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return InkWell(
      onTap: _pickAndUploadImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _aspectRatio != null
            ? AspectRatio(
                aspectRatio: _aspectRatio!,
                child: Image.network(
                  widget.content.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildUploadButton(),
                ),
              )
            : Image.network(
                widget.content.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildUploadButton(),
              ),
      ),
    );
  }
}