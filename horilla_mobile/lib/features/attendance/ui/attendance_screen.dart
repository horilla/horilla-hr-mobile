import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../../../shared/widgets/pressable.dart';
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
          AppTopBar(
            title: 'My attendance',
            trailing: _MonthPicker(overview: overview.value),
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
    final days = data.daysInMonth;
    final now = DateTime.now();
    final isCurrentMonth =
        data.month.year == now.year && data.month.month == now.month;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x6,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        _HourAccountCard(data: data),
        if (isCurrentMonth) ...[
          const SizedBox(height: AppSpace.x12),
          _WeekChart(days: data.days.results),
        ],
        const SizedBox(height: AppSpace.x18),
        // No "Request correction" action in the header: a correction needs a
        // day, so it is raised by tapping that day's row rather than from a
        // header that would have to ask which one.
        Text(
          'Activity log',
          style: AppText.cardTitle.copyWith(
            fontSize: 13.5,
            color: AppColors.ink2,
          ),
        ),
        const SizedBox(height: AppSpace.x10),
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
        if (days.isNotEmpty) ...[
          const SizedBox(height: AppSpace.x10),
          Text(
            'Tap a day to request a correction.',
            style: AppText.meta.copyWith(color: AppColors.ink4),
          ),
        ],
      ],
    );
  }
}

/// "Sep ▾" in the app bar. Offers only the months the loaded log covers.
class _MonthPicker extends ConsumerWidget {
  const _MonthPicker({required this.overview});

  final AttendanceOverview? overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(attendanceMonthProvider);
    final months = overview?.availableMonths ?? [selected];
    final label = DateFormat('MMM').format(selected);

    return Semantics(
      button: true,
      label: 'Month, ${DateFormat('MMMM yyyy').format(selected)}',
      excludeSemantics: true,
      child: Pressable(
        onTap: months.length < 2
            ? null
            : () async {
                final picked = await showModalBottomSheet<DateTime>(
                  context: context,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: AppSpace.x12),
                        for (final m in months)
                          ListTile(
                            title: Text(
                              DateFormat('MMMM yyyy').format(m),
                              style: AppText.cardTitle,
                            ),
                            trailing: m == selected
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.brandStrong,
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, m),
                          ),
                        const SizedBox(height: AppSpace.x12),
                      ],
                    ),
                  ),
                );
                if (picked != null) {
                  ref.read(attendanceMonthProvider.notifier).select(picked);
                }
              },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinHitTarget),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.cardTitle.copyWith(
                  fontSize: 14,
                  color: AppColors.brandStrong,
                ),
              ),
              if (months.length > 1)
                const Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: AppColors.brandStrong,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HourAccountCard extends StatelessWidget {
  const _HourAccountCard({required this.data});

  final AttendanceOverview data;

  @override
  Widget build(BuildContext context) {
    final account = data.hourAccount;
    final progress = account.progress;
    final expected = account.expectedHours;
    final worked = account.workedLabel;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Hour account'),
          const SizedBox(height: AppSpace.x8),
          // Wrap rather than Row: at larger text the figure and its captions
          // stop fitting on one line, and the captions drop underneath.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: AppSpace.x8,
              runSpacing: AppSpace.x6,
              children: [
                Text(
                  worked ?? '—',
                  style: AppText.statValue.copyWith(fontSize: 26),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (expected != null)
                      Text('of $expected', style: AppText.meta),
                    if (account.hasOvertime && account.overtimeLabel != null)
                      Text(
                        '+${account.overtimeLabel} OT',
                        style: AppText.meta.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (worked == null) ...[
            const SizedBox(height: AppSpace.x6),
            Text(
              'The server has no usable hour account for this month yet.',
              style: AppText.meta,
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: AppSpace.x14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.bg2,
                valueColor: const AlwaysStoppedAnimation(AppColors.brandStrong),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.x16),
          Row(
            children: [
              _Counter(label: 'Present', value: '${data.presentDays}'),
              // Amber for a count, grey for "unknown": a dash in warning
              // colour reads as a flag rather than as missing data.
              _Counter(
                label: 'Late in',
                value: data.lateIns?.toString() ?? '—',
                color: data.lateIns == null
                    ? AppColors.ink4
                    : AppColors.warning,
              ),
              _Counter(
                label: 'Early out',
                value: data.earlyOuts?.toString() ?? '—',
                color: data.earlyOuts == null
                    ? AppColors.ink4
                    : AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the hour-account counters.
///
/// Three, not the design's four: "Absent" needs the working calendar,
/// holidays and approved leave all joined together, and the app has none of
/// that. A number it cannot compute is not shown.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    this.color = AppColors.ink,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        // Its own node: label-only siblings are otherwise merged into one
        // announcement, and each figure should be its own stop.
        container: true,
        label: '$label $value',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.meta.copyWith(fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppText.mono.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mon-Sun bars for the current week. Tap a bar to read its day.
class _WeekChart extends StatefulWidget {
  const _WeekChart({required this.days});

  final List<AttendanceDay> days;

  @override
  State<_WeekChart> createState() => _WeekChartState();
}

class _WeekChartState extends State<_WeekChart> {
  late int _selected = DateTime.now().weekday - 1;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    final week = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    int secondsOn(DateTime d) {
      var total = 0;
      for (final day in widget.days) {
        if (day.date.year == d.year &&
            day.date.month == d.month &&
            day.date.day == d.day) {
          // at_work_second when the server sends it; otherwise the
          // formatted figure, which says the same thing to the minute.
          total += day.workedSeconds ?? _secondsOf(day.workedHour) ?? 0;
        }
      }
      return total;
    }

    final values = [for (final d in week) secondsOn(d)];
    // Scale to the week's longest day, but never below 9h, so a short week
    // does not draw a two-hour day as a full bar.
    final ceiling = values.fold<int>(9 * 3600, (a, b) => b > a ? b : a);
    final picked = week[_selected];
    final pickedSeconds = values[_selected];

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'This week',
                  style: AppText.cardTitle.copyWith(fontSize: 14),
                ),
              ),
              Flexible(
                // Align, or the value sits at the start of its half of the row:
                // an Expanded label and a Flexible value split the width evenly.
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    '${DateFormat('EEEE').format(picked)} · '
                    '${_hm(pickedSeconds)}',
                    textAlign: TextAlign.end,
                    style: AppText.mono.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x16),
          SizedBox(
            height: 124,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == _selected,
                      label:
                          '${DateFormat('EEEE').format(week[i])}, '
                          '${_hm(values[i])}',
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selected = i),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26,
                              height: values[i] == 0
                                  ? 6
                                  : 6 + 90 * (values[i] / ceiling),
                              decoration: BoxDecoration(
                                color: values[i] == 0
                                    ? AppColors.bg2
                                    : i == _selected
                                    ? AppColors.brandStrong
                                    : const Color(0xFFEFD3CD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: AppSpace.x8),
                            // Capped: the chart body is a fixed 124pt --
                            // graphical height, not something that should
                            // grow with text -- and an uncapped day letter
                            // overflowed it at 2x.
                            MediaQuery.withClampedTextScaling(
                              maxScaleFactor: 1.3,
                              child: Text(
                                DateFormat('E').format(week[i])[0],
                                style: AppText.mono.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: i == _selected
                                      ? AppColors.brandStrong
                                      : AppColors.ink4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static int? _secondsOf(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':').map(int.tryParse).toList();
    if (parts.length < 2 || parts.any((p) => p == null || p < 0)) return null;
    return parts[0]! * 3600 + parts[1]! * 60;
  }

  static String _hm(int seconds) =>
      '${seconds ~/ 3600}h ${(seconds % 3600 ~/ 60).toString().padLeft(2, '0')}m';
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.day});

  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final range = day.clockIn == null
        ? '—'
        : '${_hhmm(day.clockIn!)} — '
              '${day.clockOut == null ? 'in progress' : _hhmm(day.clockOut!)}';

    return Semantics(
      button: true,
      label:
          '${DateFormat('EEEE d MMMM').format(day.date)}, $range, '
          'worked ${day.workedHour ?? 'unknown'}. Request a correction.',
      excludeSemantics: true,
      child: Pressable(
        scale: 0.99,
        onTap: () => context.push('/time/correction', extra: day),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x16,
            vertical: 13,
          ),
          child: Row(
            children: [
              // Constrained rather than fixed: "Wed" at 2x needs more than
              // 44pt, and a hard width clips it instead of letting it grow.
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 44,
                  maxWidth: MediaQuery.textScalerOf(
                    context,
                  ).scale(44).clamp(44, 96),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('d').format(day.date),
                      style: AppText.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      DateFormat('EEE').format(day.date),
                      style: AppText.meta.copyWith(
                        fontSize: 10.5,
                        color: AppColors.ink4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.x8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      range,
                      style: AppText.mono.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (day.shiftName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        day.shiftName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.meta,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.x8),
              Text(
                day.workedHour ?? '—',
                style: AppText.mono.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "09:29:00" -> "09:29". The seconds are noise in a log row.
  static String _hhmm(String value) {
    final parts = value.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : value;
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
        AppSpace.x6,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: const [
        AppCard.skeleton(height: 170),
        SizedBox(height: AppSpace.x12),
        AppCard.skeleton(height: 190),
        SizedBox(height: AppSpace.x18),
        AppCard.skeleton(height: 220),
      ],
    );
  }
}
