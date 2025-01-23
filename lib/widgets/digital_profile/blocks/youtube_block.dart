// lib/widgets/digital_profile/blocks/youtube_block.dart
// Widget for embedding YouTube videos. Handles video URL parsing, preview generation using youtube_player_iframe, and manages video arrangement and visibility settings.
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as flutter_player;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as iframe_player;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../models/block.dart';
import '../../../utils/debouncer.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: _reorderVideos,
            children: _contents.asMap().entries.map((entry) {
              final index = entry.key;
              final content = entry.value;
              return _VideoCard(
                key: ValueKey('video-${content.id}'),
                content: content,
                index: index,
                onUpdate: (updated) => _updateVideo(index, updated),
                onDelete: () => _removeVideo(index),
              );
            }).toList(),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: _addVideo,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor:
                    isDarkMode ? const Color(0xFFD9D9D9) : Colors.black,
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
                    'Add Video',
                    style: TextStyle(
                      color: isDarkMode ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final BlockContent content;
  final Function(BlockContent) onUpdate;
  final VoidCallback onDelete;
  final int index;

  const _VideoCard({
    super.key,
    required this.content,
    required this.onUpdate,
    required this.onDelete,
    required this.index,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  late iframe_player.YoutubePlayerController _webController;
  late flutter_player.YoutubePlayerController _mobileController;
  bool _isLoaded = false;
  final FocusNode _urlFocus = FocusNode();
  double get _aspectRatio {
    return widget.content.url.contains('shorts/') ? 9 / 16 : 16 / 9;
  }
  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(_VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.url != widget.content.url) {
      _initController();
    }
  }

  void _initController() {
    final videoId = _getYouTubeVideoId(widget.content.url);
    if (videoId != null) {
      if (kIsWeb) {
        _webController = iframe_player.YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
          params: const iframe_player.YoutubePlayerParams(
            showFullscreenButton: false,
            mute: true,
            showControls: false,
          ),
        );
      } else {
        _mobileController = flutter_player.YoutubePlayerController(
          initialVideoId: videoId,
          flags: const flutter_player.YoutubePlayerFlags(
            autoPlay: false,
            mute: false,  // Changed to false
            hideControls: false,  // Changed to false
            enableCaption: true,
          ),
        );
      }
      setState(() => _isLoaded = true);
    } else {
      setState(() => _isLoaded = false);
    }
  }

  String? _getYouTubeVideoId(String url) {
    if (url.isEmpty) return null;
    
    try {
      // Handle YouTube Shorts URLs
      if (url.contains('shorts/')) {
        final shortsRegExp = RegExp(r'shorts/([^/?]+)');
        final shortsMatch = shortsRegExp.firstMatch(url);
        if (shortsMatch != null) {
          return shortsMatch.group(1);
        }
      }
      
      // Extract video ID from URL parameters, stripping other parameters
      if (url.contains('?v=')) {
        final videoId = url.split('?v=')[1].split('&')[0];
        return videoId;
      }
      
      // Handle youtu.be URLs
      if (url.contains('youtu.be/')) {
        final videoId = url.split('youtu.be/')[1].split('?')[0].split('&')[0];
        return videoId;
      }
    } catch (e) {
      debugPrint('Error parsing YouTube URL: $e');
      return null;
    }
    
    return null;
  }

  @override
  void dispose() {
    _urlFocus.dispose();
    if (_isLoaded) {
      if (kIsWeb) {
        _webController.close();
      } else {
        _mobileController.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final videoId = _getYouTubeVideoId(widget.content.url);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: FaIcon(FontAwesomeIcons.gripVertical, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoaded && videoId != null) ...[
                      AspectRatio(
                        aspectRatio: _aspectRatio,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb 
                            ? iframe_player.YoutubePlayer(controller: _webController)
                            : GestureDetector(
                                onTap: () {
                                  _mobileController.play();
                                },
                                child: flutter_player.YoutubePlayer(
                                  controller: _mobileController,
                                  showVideoProgressIndicator: true,
                                  actionsPadding: const EdgeInsets.all(8),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.youtube, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            focusNode: _urlFocus,
                            initialValue: widget.content.url,
                            decoration: InputDecoration(
                              hintText: 'YouTube URL',
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
                              fillColor: Colors.transparent,
                              filled: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) => widget.onUpdate(
                              widget.content.copyWith(url: value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}