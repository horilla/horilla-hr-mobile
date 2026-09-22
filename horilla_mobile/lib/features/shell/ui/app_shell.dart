import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_bottom_nav.dart';

/// Chrome around the five tab branches.
///
/// The navigation shell owns one Navigator per branch, so pushing a detail
/// screen keeps its tab lit and preserves that tab's back stack -- which is
/// the behaviour the handoff describes ("tabs are active-group based, not
/// screen based"). Expressing it structurally means no screen has to declare
/// which tab it belongs to, and no flag can drift out of sync.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const items = [
    AppNavItem(label: 'Home', icon: Icons.home_outlined),
    AppNavItem(label: 'Time', icon: Icons.schedule_outlined),
    AppNavItem(label: 'Requests', icon: Icons.inbox_outlined),
    AppNavItem(label: 'Team', icon: Icons.group_outlined),
    AppNavItem(label: 'Me', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        items: items,
        onSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the tab you are already on returns to its root, which is
          // what every other app does and what people expect.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
