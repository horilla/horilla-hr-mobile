/// Routes.
///
/// Two structural decisions worth knowing:
///
/// * The five tabs are branches of a [StatefulShellRoute], so a pushed detail
///   screen keeps its tab lit and each tab keeps its own back stack. A screen
///   like `leave_apply` lives inside the Time branch and needs no knowledge
///   that it should keep Time selected.
/// * The three screens the handoff hides the tab bar on -- signin, punch and
///   apply_job -- are top-level routes *outside* the shell. The bar is absent
///   because it is genuinely not in the tree, rather than present-but-hidden
///   behind a flag that can drift.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/ui/sign_in_screen.dart';
import '../../features/attendance/ui/attendance_screen.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/shell/ui/app_shell.dart';
import '../../shared/widgets/placeholder_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Screens reachable without a session. Everything else redirects to sign-in.
const _publicRoutes = {'/signin'};

/// [isSignedIn] is read on every navigation, and [refreshOn] tells the router
/// when to re-evaluate -- so a session lost mid-use (a refresh token that no
/// longer works, or an explicit sign-out) bounces to sign-in wherever the
/// user happens to be, rather than leaving them on a screen that can no
/// longer load anything.
GoRouter buildRouter({
  String initialLocation = '/signin',
  bool Function()? isSignedIn,
  Listenable? refreshOn,
}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    refreshListenable: refreshOn,
    redirect: isSignedIn == null
        ? null
        : (context, state) {
            final signedIn = isSignedIn();
            final atPublicRoute = _publicRoutes.contains(state.matchedLocation);

            if (!signedIn && !atPublicRoute) return '/signin';
            if (signedIn && atPublicRoute) return '/home';
            return null;
          },
    routes: [
      GoRoute(
        path: '/signin',
        builder: (context, state) => SignInScreen(
          onSignedIn: () => context.go('/home'),
        ),
      ),

      // Tab-bar-hidden, and outside the shell for that reason.
      GoRoute(
        path: '/punch',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Check out', dark: true),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const PlaceholderScreen(title: 'Notifications'),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/time',
                builder: (context, state) => const AttendanceScreen(),
                routes: [
                  GoRoute(
                    path: 'leave',
                    builder: (context, state) =>
                        const PlaceholderScreen(title: 'Leave'),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/requests',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Requests'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/team',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Team'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'Me'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
