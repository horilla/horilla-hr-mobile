import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/scope.dart';
import '../../../shared/widgets/app_bottom_nav.dart';

/// Chrome around the tab branches.
///
/// The navigation shell owns one Navigator per branch, so pushing a detail
/// screen keeps its tab lit and preserves that tab's back stack -- the
/// handoff's "tabs are active-group based, not screen based" rule, expressed
/// structurally so no screen has to declare which tab it belongs to.
///
/// Which tabs exist comes from [Modules]. A branch for a switched-off module
/// is still registered in the router -- keeping branch indices stable -- but
/// has no tab, so there is no way into it.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Every branch, in router order. `enabled` decides whether it gets a tab.
  static const branches = [
    (label: 'Home', icon: Icons.home_outlined, enabled: true),
    (label: 'Time', icon: Icons.schedule_outlined, enabled: Modules.attendance),
    (label: 'Requests', icon: Icons.inbox_outlined, enabled: Modules.requests),
    (label: 'Team', icon: Icons.group_outlined, enabled: Modules.employee),
    (label: 'Me', icon: Icons.person_outline, enabled: true),
  ];

  /// Router branch indices that currently have a tab.
  static List<int> get visibleBranchIndices => [
        for (var i = 0; i < branches.length; i++)
          if (branches[i].enabled) i,
      ];

  static List<AppNavItem> get visibleItems => [
        for (final branch in branches)
          if (branch.enabled)
            AppNavItem(label: branch.label, icon: branch.icon),
      ];

  @override
  Widget build(BuildContext context) {
    final visible = visibleBranchIndices;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        // The bar counts its own tabs; the shell counts all branches. Mapping
        // between the two here is what lets a module be switched off without
        // renumbering every branch in the router.
        // -1 when the screen lives on a branch with no tab (payslips, while
        // the Requests tab is still off). Clamping that to 0 would light
        // Home while the person is looking at a payslip.
        currentIndex: visible.indexOf(navigationShell.currentIndex),
        items: visibleItems,
        onSelected: (tabIndex) {
          final branchIndex = visible[tabIndex];
          navigationShell.goBranch(
            branchIndex,
            // Tapping the tab you are on returns to its root, which is what
            // every other app does.
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
