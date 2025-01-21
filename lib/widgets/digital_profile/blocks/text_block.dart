// lib/widgets/digital_profile/blocks/text_block.dart
//
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/block.dart';

class TextBlock extends StatefulWidget {
  final Block block;
  final Function(Block) onBlockUpdated;
  final Function(String) onBlockDeleted;

  const TextBlock({
    super.key,
    required this.block,
    required this.onBlockUpdated,
    required this.onBlockDeleted,
  });

  @override
  State<TextBlock> createState() => _TextBlockState();
}

class _TextBlockState extends State<TextBlock> {
  late List<BlockContent> _contents;
  late TextEditingController _textController;
  TextSelection? _selection;
  bool _isBoldSelected = false;
  bool _isItalicSelected = false;
  bool _isUnderlineSelected = false;


  @override
  void initState() {
    super.initState();
    _contents = List.from(widget.block.contents);
    
    // Initialize formatting from content if it exists
    if (_contents.isNotEmpty) {
      _isBoldSelected = _contents.first.isBold ?? false;
      _isItalicSelected = _contents.first.isItalic ?? false;
      _isUnderlineSelected = _contents.first.isUnderlined ?? false;
    }
    
    _textController = TextEditingController(
      text: _contents.firstOrNull?.title ?? '',
    )..addListener(_handleSelectionChange);
  }

  void _handleSelectionChange() {
    setState(() {
      _selection = _textController.selection;
    });
  }

  void _updateBlock() {
    if (_contents.isEmpty) {
      _contents.add(BlockContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _textController.text,
        url: '',
        isBold: _isBoldSelected,
        isItalic: _isItalicSelected,
        isUnderlined: _isUnderlineSelected,
        metadata: {
          'isBold': _isBoldSelected,
          'isItalic': _isItalicSelected,
          'isUnderline': _isUnderlineSelected,
        }
      ));
    } else {
      _contents[0] = _contents[0].copyWith(
        title: _textController.text,
        isBold: _isBoldSelected,
        isItalic: _isItalicSelected,
        isUnderlined: _isUnderlineSelected
      );
    }
    
    final updatedBlock = widget.block.copyWith(
      contents: _contents,
      sequence: widget.block.sequence,
    );
    widget.onBlockUpdated(updatedBlock);
  }


   void _toggleFormat(String format) {
        if (_selection == null || !_selection!.isValid) return;
        
        final text = _textController.text;
        final selection = _textController.selection;
        
        setState(() {
            if (format == 'bold') {
                _isBoldSelected = !_isBoldSelected;
            }
            
            if (format == 'italic') {
                _isItalicSelected = !_isItalicSelected;
            }
            
             if (format == 'underline') {
                _isUnderlineSelected = !_isUnderlineSelected;
            }
        });

        if (selection.start != selection.end) {
            _textController.text = text.replaceRange(
                selection.start, selection.end, text.substring(selection.start, selection.end),
            );
        }

       _updateBlock();
    }
    
  TextStyle _getStyleForPosition() {
        TextStyle style = const TextStyle(fontSize: 16);
        
        if (_isBoldSelected) {
            style = style.copyWith(fontWeight: FontWeight.bold);
        }
    
        if (_isItalicSelected) {
            style = style.copyWith(fontStyle: FontStyle.italic);
        }
    
        if (_isUnderlineSelected) {
            style = style.copyWith(decoration: TextDecoration.underline);
        }
        
        return style;
    }

  @override
  Widget build(BuildContext context) {
      
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             // Left side - Text formatting
            _buildFormatButton(
              icon: FontAwesomeIcons.bold,
              isSelected: _isBoldSelected,
              onPressed: () => _toggleFormat('bold'),
            ),
            _buildFormatButton(
              icon: FontAwesomeIcons.italic,
              isSelected: _isItalicSelected,
              onPressed: () => _toggleFormat('italic'),
            ),
            _buildFormatButton(
              icon: FontAwesomeIcons.underline,
              isSelected: _isUnderlineSelected,
              onPressed: () => _toggleFormat('underline'),
            ),
            const Spacer(), // Pushes alignment buttons to the right
            // Right side - Text alignment
            IconButton(
              icon: const Icon(Icons.format_align_left),
              onPressed: () => _updateAlignment(TextAlignment.left),
              color: widget.block.textAlignment == TextAlignment.left 
                ? Theme.of(context).primaryColor 
                : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_align_center),
              onPressed: () => _updateAlignment(TextAlignment.center),
              color: widget.block.textAlignment == TextAlignment.center 
                ? Theme.of(context).primaryColor 
                : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_align_right),
              onPressed: () => _updateAlignment(TextAlignment.right),
              color: widget.block.textAlignment == TextAlignment.right 
                ? Theme.of(context).primaryColor 
                : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _textController,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Enter your text here...',
            border: OutlineInputBorder(),
          ),
          style: _getStyleForPosition(),
          textAlign: widget.block.textAlignment?.toTextAlign() ?? TextAlign.left,
          onChanged: (value) {
            _updateBlock();
          },
        ),
      ],
    );
  }

  void _updateAlignment(TextAlignment alignment) {
    final updatedBlock = widget.block.copyWith(
      sequence: widget.block.sequence,
      textAlignment: alignment,
    );
    widget.onBlockUpdated(updatedBlock);
  }

  Widget _buildFormatButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: FaIcon(icon),
      onPressed: onPressed,
      color: isSelected ? Theme.of(context).primaryColor : null,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

extension TextAlignmentExt on TextAlignment {
  TextAlign toTextAlign() {
    switch (this) {
      case TextAlignment.left:
        return TextAlign.left;
      case TextAlignment.center:
        return TextAlign.center;
      case TextAlignment.right:
        return TextAlign.right;
    }
  }
}