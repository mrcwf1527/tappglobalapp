// lib/widgets/navigation/web_side_nav.dart
// Navigation Components: Desktop side navigation
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';

class WebSideNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  
  const WebSideNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 230,
      color: isDarkMode ? const Color(0xFF191919) : const Color(0xFFF5F5F5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Image.asset(
              isDarkMode 
                ? 'assets/logo/logo_long_white.png' 
                : 'assets/logo/logo_long_black.png',
              height: 40,
              width: 160,
              fit: BoxFit.contain,
            ),
          ),
          _buildNavItem(
            context: context,
            icon: FontAwesomeIcons.house,
            label: 'Home',
            index: 0,
          ),
          _buildNavItem(
            context: context,
            icon: FontAwesomeIcons.users,
            label: 'Leads',
            index: 1,
          ),
          _buildNavItem(
            context: context,
            icon: FontAwesomeIcons.qrcode,
            label: 'Scan',
            index: 2,
          ),
          _buildNavItem(
            context: context,
            icon: FontAwesomeIcons.envelope,
            label: 'Inbox',
            index: 3,
          ),
          _buildNavItem(
            context: context,
            icon: FontAwesomeIcons.idCard,
            label: 'Profile',
            index: 4,
          ),
          _buildNavItem(
            context: context,
            icon: FontAwesomeIcons.gear,
            label: 'Settings',
            index: 5,
          ),
          _buildNavItem(
            context: context,
            icon: FontAwesomeIcons.circleQuestion,
            label: 'Help & Support',
            index: 6,
          ),
          _buildNavItem(
            context: context,
            icon: FontAwesomeIcons.shield,
            label: 'Terms & Privacy',
            index: 7,
          ),
          const Spacer(),
          _buildLogoutButton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
              ? (isDarkMode ? const Color(0xFF252525) : Colors.black)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: FaIcon(
                  icon,
                  size: 20,
                  color: isSelected
                    ? (isDarkMode ? Colors.white : Colors.white)
                    : (isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                    ? (isDarkMode ? Colors.white : Colors.white)
                    : (isDarkMode ? Colors.white70 : Colors.black54),
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () async {
          await AuthService().signOut();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/auth');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: FaIcon(
                  FontAwesomeIcons.rightFromBracket,
                  size: 20,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sign Out',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}