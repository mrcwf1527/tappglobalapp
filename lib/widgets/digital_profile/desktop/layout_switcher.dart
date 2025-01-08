// lib/widgets/digital_profile/desktop/layout_switcher.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';

class LayoutSwitcher extends StatefulWidget {
  const LayoutSwitcher({super.key});

  @override
  State<LayoutSwitcher> createState() => _LayoutSwitcherState();
}

class _LayoutSwitcherState extends State<LayoutSwitcher> {
  String _selectedLayout = 'classic';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Layout:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLayoutOption('Classic'),
                const SizedBox(width: 16),
                _buildLayoutOption('Portrait'),
                const SizedBox(width: 16),
                _buildLayoutOption('Banner'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutOption(String text) {
    return Expanded(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedLayout == text.toLowerCase() 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey,
                  width: _selectedLayout == text.toLowerCase() ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(text),
          Radio<String>(
            value: text.toLowerCase(),
            groupValue: _selectedLayout,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedLayout = value);
              }
            },
          ),
        ],
      ),
    );
  }
}