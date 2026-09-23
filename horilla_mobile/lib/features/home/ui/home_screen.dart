import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/scope.dart';
import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../../punch/ui/punch_screen.dart';
import '../data/home_api.dart';
import '../data/home_models.dart';
import 'home_sections.dart';
import 'punch_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.brandStrong,
        onRefresh: () async => ref.refresh(homeProvider.future),
        child: _body(ref, home),
      ),
    );
  }

  /// Explicit branching rather than [AsyncValue.when].
  ///
  /// Riverpod 3 reports a failed *first* load as `AsyncLoading` carrying an
  /// error, not as `AsyncError` -- so a `when(loading:)` branch swallows the
  /// failure and shows a skeleton that never resolves. Deciding on
  /// `value`/`hasError` directly says what this screen actually means:
  ///
  ///   data present  -> show it, even mid-refresh, so a pull-to-refresh
  ///                    never blanks the screen
  ///   error, no data -> explain it, and offer a way out
  ///   neither        -> genuine first load, so skeletons
  Widget _body(WidgetRef ref, AsyncValue<HomeData> home) {
    final data = home.value;
    if (data != null) return _HomeBody(data: data);

    final error = home.error;
    if (error != null) {
      return ErrorStateCard(
        failure: error is ApiFailure ? error : const ApiUnknown(),
        onRetry: () => ref.invalidate(homeProvider),
      );
    }

    return const _HomeSkeleton();
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final firstName = data.user.fullName.split(' ').first;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _HomeAppBar(
          name: data.user.fullName,
          unread: data.unreadNotifications,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.x16,
            AppSpace.screen,
            AppSpace.scrollBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PunchCard(
                punch: data.punch,
                geofence: data.geofence,
                dateLabel: DateFormat('EEEE d MMMM').format(DateTime.now()),
                onPunch: () => context.push(
                  '/punch',
                  extra: PunchArgs(
                    // Clocked in means the next action is out, and vice versa.
                    isClockingIn: !data.punch.isClockedIn,
                    geofence: data.geofence,
                  ),
                ),
                onOpenAttendance: () => context.go('/time'),
              ),
              const SizedBox(height: AppSpace.x12),

              TodayStats(today: data.today),

              if (data.capabilities.isManager) ...[
                const SizedBox(height: AppSpace.x12),
                RoleBand(
                  role: data.capabilities.role,
                  count: 0,
                  onTap: () => context.go('/team'),
                ),
              ],

              const SizedBox(height: AppSpace.x20),
              SectionHeader(title: 'Quick actions', actionLabel: null),
              const SizedBox(height: AppSpace.x12),
              QuickActions(
                // Only destinations this build actually has. An action that
                // leads to "not available yet" is worse than no action.
                actions: [
                  if (Modules.leave)
                    QuickAction(
                      icon: Icons.event_available_outlined,
                      label: 'Apply\nleave',
                      onTap: () => context.go('/time/leave'),
                    ),
                  if (Modules.attendance)
                    QuickAction(
                      icon: Icons.schedule_outlined,
                      label: 'My\nattendance',
                      onTap: () => context.go('/time'),
                    ),
                  if (Modules.employee)
                    QuickAction(
                      icon: Icons.group_outlined,
                      label: 'Team\ndirectory',
                      onTap: () => context.go('/team'),
                    ),
                  if (Modules.payroll)
                    QuickAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Pay\nslips',
                      onTap: () => context.go('/requests/payslips'),
                    ),
                  if (Modules.requests)
                    QuickAction(
                      icon: Icons.add_circle_outline,
                      label: 'New\nrequest',
                      onTap: () => context.go('/requests'),
                    ),
                  if (Modules.helpdesk)
                    QuickAction(
                      icon: Icons.support_agent_outlined,
                      label: 'Help\ndesk',
                      onTap: () => context.go('/requests'),
                    ),
                ],
              ),

              if (data.onLeaveToday.isNotEmpty) ...[
                const SizedBox(height: AppSpace.x20),
                OnLeaveToday(
                  colleagues: data.onLeaveToday,
                  onTap: () => context.go('/team'),
                ),
              ],

              if (data.announcement != null) ...[
                const SizedBox(height: AppSpace.x12),
                AnnouncementCard(announcement: data.announcement!),
              ],

              // Greeting is rendered in the app bar; keeping the name here
              // avoids an unused-variable lint while documenting intent.
              if (firstName.isEmpty) const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({required this.name, required this.unread});

  final String name;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final greeting = switch (DateTime.now().hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };

    return Container(
      color: AppColors.surface,
      padding: PlatformChrome.appBarPadding,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/me'),
            child: AppAvatar(name: name.isEmpty ? '?' : name, size: 40),
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: AppText.meta),
                Text(
                  name.isEmpty ? 'Welcome' : name,
                  style: AppText.cardTitle.copyWith(fontSize: 15.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _NotificationBell(unread: unread),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
      child: GestureDetector(
        onTap: () => context.go('/home/notifications'),
        child: SizedBox(
          width: kMinHitTarget,
          height: kMinHitTarget,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none,
                size: 22,
                color: AppColors.ink2,
              ),
              if (unread > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches the real screen's geometry, per the handoff: skeletons shaped like
/// the cards they stand in for, never a spinner over the whole screen.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x28,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: const [
        AppCard.skeleton(height: 200),
        SizedBox(height: AppSpace.x12),
        AppCard.skeleton(height: 84),
        SizedBox(height: AppSpace.x20),
        AppCard.skeleton(height: 96),
      ],
    );
  }
}
