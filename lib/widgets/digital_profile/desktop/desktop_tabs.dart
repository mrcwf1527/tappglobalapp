// lib/widgets/digital_profile/desktop/desktop_tabs.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';

class DesktopTabs extends StatelessWidget {
  final TabController tabController;

  const DesktopTabs({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TabBar(
      controller: tabController,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
      labelColor: isDark ? Colors.white : Colors.black,
      unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
      tabs: const [
        Tab(text: 'Header'),
        Tab(text: 'Blocks'),
        Tab(text: 'Insights'),
        Tab(text: 'Settings'),
      ],
    );
  }
}