// lib/widgets/navigation/desktop_sidebar.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigate;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Color(0xFF191919),
        border: Border(
          right: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'TAPP!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem(0, FontAwesomeIcons.house, 'Overview'),
                  _buildNavItem(1, FontAwesomeIcons.users, 'All Leads'),
                  _buildDisabledNavItem(FontAwesomeIcons.chartLine, 'Lead Analytics'),
                  _buildNavItem(2, FontAwesomeIcons.qrcode, 'Scan Card'),
                  _buildNavItem(3, FontAwesomeIcons.envelope, 'Inbox'),
                  _buildNavItem(4, FontAwesomeIcons.user, 'Digital Profile'),
                  _buildDisabledNavItem(FontAwesomeIcons.chartBar, 'Analytics & Reports'),
                  _buildNavItem(12, FontAwesomeIcons.gear, 'Settings'),
                ],
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const FaIcon(
              FontAwesomeIcons.rightFromBracket,
              color: Colors.red,
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => onNavigate(-1),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
  
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFD9D9D9) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => onNavigate(index),
        leading: FaIcon(
          icon,
          color: isSelected ? Colors.black : Colors.white,
          size: 18,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledNavItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        enabled: false,
        leading: FaIcon(
          icon,
          color: Colors.grey,
          size: 18,
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}