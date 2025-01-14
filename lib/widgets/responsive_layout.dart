// lib/widgets/responsive_layout.dart
// Implements responsive design patterns, Handles different layouts for mobile, tablet, desktop, Provides utility methods for screen size detection
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context) && desktopLayout != null) {
      return desktopLayout!;
    }
    if (isTablet(context) && tabletLayout != null) {
      return tabletLayout!;
    }
    return mobileLayout;
  }
}