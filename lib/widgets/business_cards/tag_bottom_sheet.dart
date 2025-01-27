// lib/widgets/business_cards/tag_bottom_sheet.dart
// Bottom sheet widget displaying filterable list of tags with multi-select capability and option to create new tags.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../providers/tag_provider.dart';
import 'create_tag_dialog.dart';
import '../../models/tag.dart';

class TagBottomSheet extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsSelected;

  const TagBottomSheet({
    super.key,
    required this.selectedTags,
    required this.onTagsSelected,
  });

  @override
  State<TagBottomSheet> createState() => _TagBottomSheetState();
}

class _TagBottomSheetState extends State<TagBottomSheet> {
  late List<String> _selectedTags;
  bool _isSettingsMode = false; // Track whether in settings mode

  @override
  void initState() {
    super.initState();
     _selectedTags = List.from(widget.selectedTags); // Initialize selected tags
  }

  void _showCreateTagDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTagDialog(
        onTagCreated: (tag) {
          setState(() => _selectedTags.add(tag.id)); //Add created tag to state
        },
      ),
    );
  }

  // Helper function to parse hex color string
    Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse(hexColor, radix: 16) + 0xFF000000);
  }

  // Helper function to check light/dark color
  bool _isLightColor(String hexColor) {
    Color color = _getColorFromHex(hexColor);
    double luminance = (0.299 * color.r + 
                       0.587 * color.g + 
                       0.114 * color.b) / 255;
    return luminance > 0.6;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isSettingsMode ? 'Manage Tags' : 'Add Tags', // Title changes based on mode
                  style: const TextStyle(fontSize: 20)
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isSettingsMode ? Icons.check : Icons.settings), // Icon changes based on mode
                      onPressed: () => setState(() => _isSettingsMode = !_isSettingsMode), // Toggle mode
                    ),
                    if (!_isSettingsMode) // Show Apply Tags button only in select mode
                      TextButton(
                        onPressed: () {
                          widget.onTagsSelected(_selectedTags);
                          Navigator.pop(context);
                        },
                        child: const Text('Apply Tags'),
                      ),
                  ],
                ),
              ],
            ),
             if (!_isSettingsMode) ...[ // Search field only in select mode
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search or create tags',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Consumer<TagProvider>(
              builder: (context, tagProvider, _) => 
                tagProvider.tags.isEmpty 
                  ? _buildEmptyState() 
                  : _buildTagList(tagProvider),
            ),
          ],
        ),
      ),
    );
  }

  // Build empty state UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.search, size: 48, color: Colors.grey),
          const Text('No Tags Found'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _showCreateTagDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.light 
                ? Colors.black 
                : Colors.white,
              foregroundColor: Theme.of(context).brightness == Brightness.light 
                ? Colors.white 
                : Colors.black,
              minimumSize: const Size(200, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create New Tag'),
          ),
        ],
      ),
    );
  }

  // Edit tag dialog
  void _showEditTagDialog(Tag tag) {
    String name = tag.name;
    Color selectedColor = _getColorFromHex(tag.color);
    String previewText = tag.name;

    final presetColors = [
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

    void openColorPicker() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presetColors.map((color) => GestureDetector(
                    onTap: () {
                      selectedColor = color;
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) => selectedColor = color,
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(labelText: 'Tag Name'),
              maxLength: 30,
              onChanged: (value) {
                name = value;
                previewText = value.isEmpty ? 'Preview' : value;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Tag Color'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isLightColor('#${selectedColor.value.toRadixString(16).substring(2)}') ? Colors.black : selectedColor,
                  ),
                ),
                child: Text(
                  previewText,
                  style: TextStyle(
                    color: _isLightColor('#${selectedColor.value.toRadixString(16).substring(2)}') ? Colors.black : Colors.white,
                  ),
                ),
              ),
              onTap: openColorPicker,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final colorHex = '#${selectedColor.value.toRadixString(16).substring(2)}';
              context.read<TagProvider>().updateTag(tag.userId, tag.id, name, colorHex);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Delete tag dialog
  void _deleteTag(Tag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Are you sure you want to delete "${tag.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final tagProvider = context.read<TagProvider>();
              tagProvider.deleteTag(tag.userId, tag.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Build the tag list
  Widget _buildTagList(TagProvider tagProvider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tagProvider.tags.map((tag) => _isSettingsMode // Conditional chip display based on settings mode
          ? _buildSettingsChip(tag)
          : _buildSelectableChip(tag)),
        if (!_isSettingsMode) // Add tag button only in selection mode
          ActionChip(
            label: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16),
                SizedBox(width: 4),
                Text('Add Tag'),
              ],
            ),
            onPressed: _showCreateTagDialog,
            backgroundColor: Theme.of(context).brightness == Brightness.light 
              ? Colors.grey[200]
              : Colors.grey[800],
          ),
      ],
    );
  }

  // Build the settings chip for tag management
  Widget _buildSettingsChip(Tag tag) {
    return InputChip(
      label: Text(
        tag.name,
        style: TextStyle(
          color: _isLightColor(tag.color) ? Colors.black : Colors.white,
        ),
      ),
      backgroundColor: _getColorFromHex(tag.color),
      onPressed: () => _showEditTagDialog(tag),
      deleteIcon: Icon(
        Icons.delete, 
        size: 18,
        color: _isLightColor(tag.color) ? Colors.black : Colors.white,
      ),
      onDeleted: () => _deleteTag(tag),
    );
  }

  // Build selectable chip for tag selection
  Widget _buildSelectableChip(Tag tag) {
    return FilterChip(
      label: Text(
        tag.name,
        style: TextStyle(
          color: _isLightColor(tag.color) ? Colors.black : Colors.white,
        ),
      ),
      selected: _selectedTags.contains(tag.id),
      backgroundColor: _getColorFromHex(tag.color),
      selectedColor: _getColorFromHex(tag.color),
      checkmarkColor: _isLightColor(tag.color) ? Colors.black : Colors.white,
      side: BorderSide(
        color: _isLightColor(tag.color) ? Colors.black : _getColorFromHex(tag.color),
        width: 1.0,
      ),
      showCheckmark: true,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTags.add(tag.id);
          } else {
            _selectedTags.remove(tag.id);
          }
        });
      },
    );
  }
}