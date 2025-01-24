// lib/widgets/digital_profile/blocks/spacer_block.dart
// A widget that adds configurable vertical spacing between content blocks with various divider styles (none, thin line, thick line, dotted, dashed, double lines, ellipsis).
import 'package:flutter/material.dart';
import '../../../models/block.dart';

enum DividerStyle {
  none,
  thinLine,
  thickLine,
  dottedLine,
  dashed,
  doubleLines,
  ellipsis
}

class SpacerBlock extends StatefulWidget {
  final Block block;
  final Function(Block) onBlockUpdated;
  final Function(String) onBlockDeleted;

  const SpacerBlock({
    super.key,
    required this.block,
    required this.onBlockUpdated,
    required this.onBlockDeleted,
  });

  @override
  State<SpacerBlock> createState() => _SpacerBlockState();
}

class _SpacerBlockState extends State<SpacerBlock> {
  late List<BlockContent> _contents;
  late double _height;
  late DividerStyle _dividerStyle;

  @override
  void initState() {
    super.initState();
    _contents = List.from(widget.block.contents);
    _height = _contents.firstOrNull?.metadata?['height'] ?? 16.0;
    _dividerStyle = _getDividerStyle(_contents.firstOrNull?.metadata?['dividerStyle']);
  }

  DividerStyle _getDividerStyle(String? style) {
    return style != null 
        ? DividerStyle.values.firstWhere(
            (e) => e.name == style,
            orElse: () => DividerStyle.none)
        : DividerStyle.none;
  }

  void _updateBlock({double? height, DividerStyle? style}) {
    if (height != null) _height = height;
    if (style != null) _dividerStyle = style;

    if (_contents.isEmpty) {
      _contents.add(BlockContent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        url: '',
        metadata: {
          'height': _height,
          'dividerStyle': _dividerStyle.name,
        },
      ));
    } else {
      _contents[0] = _contents[0].copyWith(
        metadata: {
          'height': _height,
          'dividerStyle': _dividerStyle.name,
        },
      );
    }

    widget.onBlockUpdated(widget.block.copyWith(
      contents: _contents,
      sequence: widget.block.sequence,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Block name and controls row remains unchanged
        
        const SizedBox(height: 16),
        const Text(
          'Add some empty vertical space to your page.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        
        // Height Slider with px display
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _height,
                min: 0,
                max: 600,
                divisions: 600,
                onChanged: (value) => _updateBlock(height: value),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_height.round()} px',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: DividerStyle.values.map((style) => _DividerOption(
            style: style,
            isSelected: _dividerStyle == style,
            onTap: () => _updateBlock(style: style),
          )).toList(),
        ),
        
        const SizedBox(height: 24),
        _buildDivider(), // Preview remains unchanged
      ],
    );
  }
  
  Widget _buildDivider() {
    final Color dividerColor = Colors.black;
    
    switch (_dividerStyle) {
      case DividerStyle.none:
        return SizedBox(height: _height);
      case DividerStyle.thinLine:
        return Divider(height: _height, thickness: 1, color: dividerColor);
      case DividerStyle.thickLine:
        return Divider(height: _height, thickness: 3, color: dividerColor);
      case DividerStyle.dottedLine:
        return _CustomDivider(
          height: _height,
          builder: (color) => CustomPaint(
            size: Size.fromHeight(_height),
            painter: DottedLinePainter(color: dividerColor),
          ),
        );
      case DividerStyle.dashed:
        return _CustomDivider(
          height: _height,
          builder: (color) => CustomPaint(
            size: Size.fromHeight(_height),
            painter: DashedLinePainter(color: dividerColor),
          ),
        );
      case DividerStyle.doubleLines:
        return _CustomDivider(
          height: _height,
          builder: (color) => CustomPaint(
            size: Size.fromHeight(_height),
            painter: DoubleLinePainter(color: dividerColor),
          ),
        );
      case DividerStyle.ellipsis:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: _height),
            const Text('• • •', style: TextStyle(fontSize: 24, color: Colors.black)),
          ],
        );
    }
  }
}

class _DividerOption extends StatelessWidget {
  final DividerStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const _DividerOption({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio(
              value: style,
              groupValue: isSelected ? style : null,
              onChanged: (_) => onTap(),
            ),
            const SizedBox(width: 8),
            Text(style.name.split(RegExp(r'(?=[A-Z])')).join(' ').toUpperCase()),
          ],
        ),
      ),
    );
  }
}

class _CustomDivider extends StatelessWidget {
  final double height;
  final Widget Function(Color color) builder;

  const _CustomDivider({
    required this.height,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(Theme.of(context).dividerColor);
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  
  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 4.0;
    final centerY = size.height / 2;
    
    for (double x = 0; x < size.width; x += spacing * 2) {
      canvas.drawCircle(Offset(x, centerY), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final centerY = size.height / 2;
    
    for (double x = 0; x < size.width; x += dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(x, centerY),
        Offset(x + dashWidth, centerY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DoubleLinePainter extends CustomPainter {
  final Color color;
  
  DoubleLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final centerY = size.height / 2;
    
    canvas.drawLine(
      Offset(0, centerY - 2),
      Offset(size.width, centerY - 2),
      paint,
    );
    
    canvas.drawLine(
      Offset(0, centerY + 2),
      Offset(size.width, centerY + 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}