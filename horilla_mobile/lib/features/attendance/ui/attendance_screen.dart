import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../data/attendance_api.dart';
import '../data/attendance_models.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(attendanceOverviewProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: PlatformChrome.appBarPadding,
            child: Text('Attendance', style: AppText.appBarTitle),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandStrong,
              onRefresh: () async =>
                  ref.refresh(attendanceOverviewProvider.future),
              child: _body(ref, overview),
            ),
          ),
        ],
      ),
    );
  }

  /// Same branching as Home, and for the same reason: Riverpod 3 reports a
  /// failed first load as AsyncLoading carrying an error, so a `when(loading:)`
  /// branch would show a skeleton that never resolves.
  Widget _body(WidgetRef ref, AsyncValue<AttendanceOverview> overview) {
    final data = overview.value;
    if (data != null) return _AttendanceBody(data: data);

    final error = overview.error;
    if (error != null) {
      return ErrorStateCard(
        failure: error is ApiFailure ? error : const ApiUnknown(),
        onRetry: () => ref.invalidate(attendanceOverviewProvider),
      );
    }
    return const _AttendanceSkeleton();
  }
}

class _AttendanceBody extends StatelessWidget {
  const _AttendanceBody({required this.data});

  final AttendanceOverview data;

  @override
  Widget build(BuildContext context) {
    final days = data.days.results;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x18,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        _HourAccountCard(account: data.hourAccount),
        const SizedBox(height: AppSpace.x20),
        SectionHeader(
          title: 'Activity',
          actionLabel: 'Request correction',
          onAction: () => context.go('/requests'),
        ),
        const SizedBox(height: AppSpace.x12),
        if (days.isEmpty)
          const _EmptyActivity()
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.line2),
                  _ActivityRow(day: days[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _HourAccountCard extends StatelessWidget {
  const _HourAccountCard({required this.account});

  final HourAccount account;

  @override
  Widget build(BuildContext context) {
    final progress = account.progress;
    final expected = account.expectedHours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EyebrowLabel(
            account.month.isEmpty
                ? 'Hour account'
                : '${account.month} ${account.year}',
          ),
          const SizedBox(height: AppSpace.x8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(account.workedHours, style: AppText.statValue),
              const SizedBox(width: AppSpace.x8),
              if (expected != null)
                Text('of $expected', style: AppText.meta),
              const Spacer(),
              if (account.hasOvertime)
                Text(
                  '+${account.overtime} OT',
                  style: AppText.meta.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpace.x14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.bg2,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.brandStrong),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.day});

  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final range = day.clockIn == null
        ? '—'
        : '${day.clockIn} – ${day.clockOut ?? 'now'}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: AppSpace.x12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d').format(day.date),
                  style: AppText.cardTitle.copyWith(fontSize: 15),
                ),
                Text(
                  DateFormat('EEE').format(day.date).toUpperCase(),
                  style: AppText.eyebrow,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(range, style: AppText.mono.copyWith(fontSize: 12.5)),
                if (day.isOpen) ...[
                  const SizedBox(height: AppSpace.x4),
                  const StatusChip('Open', tone: StatusTone.warning),
                ],
              ],
            ),
          ),
          Text(
            day.workedHour ?? '—',
            style: AppText.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Nothing yet'),
          const SizedBox(height: AppSpace.x8),
          Text(
            'Your attendance will appear here once you check in.',
            style: AppText.body,
          ),
        ],
      ),
    );
  }
}

class _AttendanceSkeleton extends StatelessWidget {
  const _AttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x18,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: const [
        AppCard.skeleton(height: 120),
        SizedBox(height: AppSpace.x20),
        AppCard.skeleton(height: 220),
      ],
    );
  }
}
