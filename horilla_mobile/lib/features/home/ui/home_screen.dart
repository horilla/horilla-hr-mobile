import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/scope.dart';
import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/horilla_mark.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../../announcements/ui/announcements_screen.dart';
import '../../punch/ui/punch_screen.dart';
import '../data/home_api.dart';
import '../../approvals/data/approval_models.dart';
import '../../approvals/data/approvals_controller.dart';
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

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _HomeAppBar(name: data.user.fullName, unread: data.unreadNotifications),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            AppSpace.x6,
            AppSpace.screen,
            AppSpace.scrollBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PunchCard(
                punch: data.punch,
                geofence: data.geofence,
                today: data.today,
                dateLabel: DateFormat('EEE d MMM').format(DateTime.now()),
                onPunch: () => context.push(
                  '/punch',
                  extra: PunchArgs(
                    // Clocked in means the next action is out, and vice versa.
                    isClockingIn: !data.punch.isClockedIn,
                    geofence: data.geofence,
                    today: data.today,
                    clockInTime: data.punch.clockInTime,
                  ),
                ),
              ),

              // Hidden at zero rather than telling every manager "0 requests
              // need you".
              if (data.capabilities.isManager)
                _ApprovalsBand(pendingApprovals: data.pendingApprovals),

              const SizedBox(height: 22),
              Text(
                'Quick actions',
                style: AppText.cardTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpace.x12),
              QuickActions(
                // Only destinations this build actually has. An action that
                // leads to "not available yet" is worse than no action.
                actions: [
                  if (Modules.leave) ...[
                    QuickAction(
                      icon: Icons.event_available_outlined,
                      label: 'Apply leave',
                      onTap: () => context.go('/time/leave/apply'),
                    ),
                    // The balances screen's only way in: "Apply leave" goes
                    // straight to the form, as the handoff draws it.
                    QuickAction(
                      icon: Icons.donut_large_outlined,
                      label: 'Leave balances',
                      tone: QuickActionTone.success,
                      onTap: () => context.go('/time/leave'),
                    ),
                  ],
                  if (Modules.attendance)
                    QuickAction(
                      icon: Icons.schedule_outlined,
                      label: 'Attendance',
                      tone: QuickActionTone.warning,
                      onTap: () => context.go('/time'),
                    ),
                  if (Modules.employee)
                    QuickAction(
                      icon: Icons.group_outlined,
                      label: 'Directory',
                      tone: QuickActionTone.info,
                      onTap: () => context.go('/team/directory'),
                    ),
                  if (Modules.payroll)
                    QuickAction(
                      icon: Icons.receipt_long_outlined,
                      label: 'Payslips',
                      tone: QuickActionTone.warning,
                      onTap: () => context.go('/requests/payslips'),
                    ),
                  if (Modules.requests)
                    QuickAction(
                      icon: Icons.add,
                      label: 'New request',
                      onTap: () => context.go('/requests'),
                    ),
                ],
              ),

              if (data.onLeaveToday.isNotEmpty) ...[
                const SizedBox(height: AppSpace.x16),
                OnLeaveToday(
                  colleagues: data.onLeaveToday,
                  onTap: () => context.go('/team'),
                ),
              ],

              if (data.announcement != null) ...[
                const SizedBox(height: AppSpace.x12),
                AnnouncementCard(
                  announcement: data.announcement!,
                  onTap: () =>
                      openAnnouncement(context, ref, data.announcement!.id),
                  onSeeAll: () => context.push('/home/announcements'),
                ),
              ],
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

    return Padding(
      padding: PlatformChrome.appBarPaddingOf(context),
      child: Row(
        children: [
          const HorillaMarkTile(),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: AppText.meta.copyWith(fontSize: 11)),
                Text(
                  name.isEmpty ? 'Welcome' : name,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _NotificationBell(unread: unread),
          const SizedBox(width: AppSpace.x4),
          Semantics(
            button: true,
            label: 'My profile',
            excludeSemantics: true,
            child: Pressable(
              onTap: () => context.go('/me'),
              child: SizedBox(
                width: kMinHitTarget,
                height: kMinHitTarget,
                child: Center(child: _BrandAvatar(name: name)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The filled brand circle in the top-right corner. Distinct from
/// [AppAvatar]'s tinted squircles on purpose: this one is *you*.
class _BrandAvatar extends StatelessWidget {
  const _BrandAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
        ? parts.first.characters.first.toUpperCase()
        : (parts.first.characters.first + parts.last.characters.first)
              .toUpperCase();
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.brandStrong,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppText.cardTitle.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.surface,
        ),
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
      excludeSemantics: true,
      child: Pressable(
        onTap: () => context.go('/home/notifications'),
        child: SizedBox(
          width: kMinHitTarget,
          height: kMinHitTarget,
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 19,
                    color: AppColors.ink,
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 8,
                      right: 9,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
        AppCard.skeleton(height: 240, radius: AppRadii.hero),
        SizedBox(height: AppSpace.x28),
        AppCard.skeleton(height: 90),
        SizedBox(height: AppSpace.x16),
        AppCard.skeleton(height: 96),
      ],
    );
  }
}

class _ApprovalsBand extends ConsumerWidget {
  const _ApprovalsBand({required this.pendingApprovals});

  /// From the home aggregate. When present this band costs nothing extra --
  /// no six-source, up-to-thirty-request fetch just to show a count.
  final PendingApprovals? pendingApprovals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromServer = pendingApprovals;
    if (fromServer != null) {
      if (fromServer.total == 0) return const SizedBox.shrink();
      return _band(
        context,
        count: fromServer.total,
        subtitle: fromServer.summary(),
      );
    }

    // A server before PR #3407 has no pending_approvals field at all --
    // fall back to counting the full inbox client-side, as this always did.
    final inbox = ref.watch(approvalsProvider).value;
    if (inbox == null || inbox.items.isEmpty) return const SizedBox.shrink();
    return _band(context, count: inbox.items.length, subtitle: inbox.summary());
  }

  Widget _band(
    BuildContext context, {
    required int count,
    required String subtitle,
  }) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.x14),
    child: RoleBand(
      // The approvals band for HR executives too: the HR desk it would
      // otherwise advertise is not built.
      role: 'manager',
      count: count,
      subtitle: subtitle,
      onTap: () => context.go('/team/approvals'),
    ),
  );
}
