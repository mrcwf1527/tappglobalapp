// lib/widgets/responsive_layout.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
  });

  static bool isMobile(BuildContext context) => true;
  static bool isTablet(BuildContext context) => false;
  static bool isDesktop(BuildContext context) => false;

  @override
  Widget build(BuildContext context) {
    return mobileLayout;
  }
}