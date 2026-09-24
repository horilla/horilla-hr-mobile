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
import '../../features/attendance/data/attendance_models.dart';
import '../../features/attendance/ui/attendance_screen.dart';
import '../../features/attendance/ui/correction_screen.dart';
import '../../features/employee/ui/directory_screen.dart';
import '../../features/employee/ui/me_screen.dart';
import '../../features/employee/ui/personal_info_screen.dart';
import '../../features/home/data/home_models.dart';
import '../../features/home/ui/home_screen.dart';
import '../../features/punch/ui/punch_screen.dart';
import '../../features/leave/ui/leave_allocation_screen.dart';
import '../../features/leave/ui/leave_apply_screen.dart';
import '../../features/leave/ui/leave_screen.dart';
import '../../features/notifications/ui/notifications_screen.dart';
import '../../features/payroll/ui/payslip_detail_screen.dart';
import '../../features/payroll/ui/payslips_screen.dart';
import '../../features/requests/ui/asset_request_screen.dart';
import '../../features/requests/ui/reimburse_screen.dart';
import '../../features/requests/ui/requests_screen.dart';
import '../../features/requests/ui/shift_request_screen.dart';
import '../../features/shell/ui/app_shell.dart';
import '../scope.dart';
import '../../shared/widgets/not_in_this_build_screen.dart';

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
        builder: (context, state) =>
            SignInScreen(onSignedIn: () => context.go('/home')),
      ),

      // Tab-bar-hidden, and outside the shell for that reason.
      GoRoute(
        path: '/punch',
        builder: (context, state) {
          // Passed as extra rather than re-fetched: home already knows the
          // punch state and the fence, and a second fetch here would let the
          // two screens disagree about which way the punch goes.
          final args = state.extra;
          return PunchScreen(
            isClockingIn: args is PunchArgs ? args.isClockingIn : true,
            geofence: args is PunchArgs
                ? args.geofence
                : const GeofenceState(enabled: false),
            today: args is PunchArgs ? args.today : TodayTotals.zero,
            clockInTime: args is PunchArgs ? args.clockInTime : null,
          );
        },
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
                    builder: (context, state) => const NotificationsScreen(),
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
                    path: 'correction',
                    builder: (context, state) {
                      // The day comes from the row that was tapped; there is
                      // no useful screen here without one.
                      final day = state.extra;
                      if (day is! AttendanceDay) {
                        return const AttendanceScreen();
                      }
                      return CorrectionScreen(day: day);
                    },
                  ),
                  GoRoute(
                    path: 'leave',
                    builder: (context, state) => const LeaveScreen(),
                    routes: [
                      // Inside the Time branch, so applying for leave keeps
                      // the Time tab lit -- the handoff's group rule.
                      GoRoute(
                        path: 'apply',
                        builder: (context, state) => const LeaveApplyScreen(),
                      ),
                      GoRoute(
                        path: 'allocation',
                        builder: (context, state) =>
                            const LeaveAllocationScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // Registered even when switched off, so branch indices stay
              // stable and re-enabling a module is one flag rather than a
              // renumbering exercise.
              GoRoute(
                path: '/requests',
                builder: (context, state) => Modules.requests
                    ? const RequestsScreen()
                    : const NotInThisBuildScreen(title: 'Requests'),
                routes: [
                  GoRoute(
                    path: 'payslips',
                    builder: (context, state) => Modules.payroll
                        ? const PayslipsScreen()
                        : const NotInThisBuildScreen(title: 'Payslips'),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => Modules.payroll
                            ? PayslipDetailScreen(
                                payslipId:
                                    int.tryParse(
                                      state.pathParameters['id'] ?? '',
                                    ) ??
                                    0,
                              )
                            : const NotInThisBuildScreen(title: 'Payslip'),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'shift-request',
                    builder: (context, state) => const ShiftRequestScreen(),
                  ),
                  GoRoute(
                    path: 'asset',
                    builder: (context, state) => const AssetRequestScreen(),
                  ),
                  GoRoute(
                    path: 'reimburse',
                    builder: (context, state) => const ReimburseScreen(),
                  ),
                  // Helpdesk and the ticket thread live here per the
                  // handoff's nav model, but neither is built -- Modules.
                  // helpdesk is not consulted because there is no real screen
                  // yet for it to select. The route exists so a deep link
                  // here (a push notification, say) explains itself instead
                  // of the router reporting no match at all.
                  GoRoute(
                    path: 'helpdesk',
                    builder: (context, state) =>
                        const NotInThisBuildScreen(title: 'Helpdesk'),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/team',
                builder: (context, state) => Modules.employee
                    ? const DirectoryScreen()
                    : const NotInThisBuildScreen(title: 'Team'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => const MeScreen(),
                routes: [
                  GoRoute(
                    path: 'personal-information',
                    builder: (context, state) => const PersonalInfoScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
