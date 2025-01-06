// lib/widgets/responsive_layout.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget desktopLayout;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    this.tabletLayout,
    required this.desktopLayout,
  });

  static bool isMobile(BuildContext context) => 
    MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) => 
    MediaQuery.of(context).size.width >= 600 && 
    MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) => 
    MediaQuery.of(context).size.width >= 1200;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktopLayout;
        }
        if (constraints.maxWidth >= 600) {
          return tabletLayout ?? mobileLayout;
        }
        return mobileLayout;
      },
    );
  }
}