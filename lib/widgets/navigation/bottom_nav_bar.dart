// lib/widgets/navigation/bottom_nav_bar.dart
// Navigation Components: Mobile bottom navigation
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF191919)
            : Colors.white,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFD9D9D9)
            : Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 22,
        elevation: 0,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF191919)
            : Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house),
            activeIcon: FaIcon(FontAwesomeIcons.house),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.users),
            activeIcon: FaIcon(FontAwesomeIcons.users),
            label: 'Leads',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.qrcode),
            activeIcon: FaIcon(FontAwesomeIcons.qrcode),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.envelope),
            activeIcon: FaIcon(FontAwesomeIcons.envelope),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.idCard),
            activeIcon: FaIcon(FontAwesomeIcons.idCard),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}