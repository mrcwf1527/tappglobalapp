// lib/widgets/business_cards/create_tag_dialog.dart
// Dialog widget for creating new tags with name input and color picker, integrated with TagProvider for persistence.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../../models/tag.dart';
import '../../providers/tag_provider.dart';

class CreateTagDialog extends StatefulWidget {
  final Function(Tag) onTagCreated;

  const CreateTagDialog({super.key, required this.onTagCreated});

  @override
  State<CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<CreateTagDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _previewText = 'Preview'; // Added _previewText variable
  Color _selectedColor = const Color(0xFF000000); // Black as default - Updated default color

  final List<Color> presetColors = [
    const Color(0xFFE57373), // Red
    const Color(0xFFFF8A65), // Deep Orange
    const Color(0xFFFFF176), // Yellow
    const Color(0xFF81C784), // Green
    const Color(0xFF4FC3F7), // Light Blue
    const Color(0xFF7986CB), // Indigo
    const Color(0xFF9575CD), // Deep Purple
    const Color(0xFFF06292), // Pink
    const Color(0xFF4DB6AC), // Teal
    const Color(0xFFFF8A65), // Coral
  ];

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preset color grid
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presetColors.map((color) => GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              // Standard color picker
              ColorPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) => setState(() => _selectedColor = color),
                enableAlpha: false,
                hexInputBar: true,
                displayThumbColor: true,
                pickerAreaHeightPercent: 0.8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

    bool _isLightColor(Color color) {
    double luminance = (0.299 * color.r + 
                       0.587 * color.g + 
                       0.114 * color.b) / 255;
    return luminance > 0.6;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Tag'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Tag Name'),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Required';
                }
                if ((value?.length ?? 0) > 30) {
                  return 'Tag name cannot exceed 30 characters';
                }
                return null;
              },
              maxLength: 30, // This adds a character counter
              onSaved: (value) => _name = value ?? '',
              onChanged: (value) {
                setState(() {
                  _previewText = value.isEmpty ? 'Preview' : value;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Tag Color'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isLightColor(_selectedColor) ? Colors.black : _selectedColor,
                      width: 1.0,
                    ),
                ),
                child: Text(
                  _previewText, // Updated to display _previewText
                  style: TextStyle(
                    color: _isLightColor(_selectedColor) ? Colors.black : Colors.white,
                  ),
                ),
              ),
              onTap: _openColorPicker,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        // In _CreateTagDialogState class
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                // Convert RGB values to hex
                final colorHex = '#${(_selectedColor.r * 255).round().toRadixString(16).padLeft(2, '0')}'
                                 '${(_selectedColor.g * 255).round().toRadixString(16).padLeft(2, '0')}'
                                 '${(_selectedColor.b * 255).round().toRadixString(16).padLeft(2, '0')}';
                if (!context.mounted) return;
                Provider.of<TagProvider>(context, listen: false)
                    .createTag(userId, _name, colorHex)
                    .then((tag) {
                  widget.onTagCreated(tag);
                  if (context.mounted) Navigator.pop(context);
                });
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}