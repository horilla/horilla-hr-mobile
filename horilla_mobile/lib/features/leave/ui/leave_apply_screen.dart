import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/toast.dart';
import '../data/leave_api.dart';
import '../data/leave_models.dart';
import 'leave_screen.dart' show formatDays;

/// Screen 6 of the handoff: type, dates, reason, submit.
///
/// The day count is an estimate and is labelled as one. Whether weekends and
/// holidays count depends on the company's weekly-off setup and on each leave
/// type's policy, and the server sends the app neither -- so the calendar
/// marks holidays as information, and the server settles the final number.
class LeaveApplyScreen extends ConsumerStatefulWidget {
  const LeaveApplyScreen({super.key});

  @override
  ConsumerState<LeaveApplyScreen> createState() => _LeaveApplyScreenState();
}

class _LeaveApplyScreenState extends ConsumerState<LeaveApplyScreen> {
  final _reason = TextEditingController();

  LeaveBalance? _selected;
  DateTime? _start;
  DateTime? _end;
  LeaveBreakdown _startBreakdown = LeaveBreakdown.fullDay;
  LeaveBreakdown _endBreakdown = LeaveBreakdown.fullDay;

  bool _busy = false;
  String? _error;
  String? _reasonError;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  LeaveApplication? get _application {
    final selected = _selected;
    final start = _start;
    if (selected == null || start == null) return null;
    final end = _end ?? start;
    final single = end == start;
    return LeaveApplication(
      leaveTypeId: selected.type.id,
      startDate: start,
      endDate: end,
      startBreakdown: _startBreakdown,
      // A single day has one part; the end mirrors it.
      endBreakdown: single ? _startBreakdown : _endBreakdown,
      reason: _reason.text.trim(),
    );
  }

  /// Tap a start day, then an end day. A tap before the start, or after a
  /// complete range, begins a new range -- the prototype's rule.
  void _pickDay(DateTime day) {
    setState(() {
      final start = _start;
      if (start == null || _end != null || day.isBefore(start)) {
        _start = day;
        _end = null;
      } else {
        _end = day;
      }
      _error = null;
    });
  }

  Future<void> _submit() async {
    final application = _application;
    final session = ref.read(sessionProvider);

    setState(() {
      _error = null;
      _reasonError = null;
    });

    if (_selected == null) {
      setState(() => _error = 'Choose a leave type.');
      return;
    }
    if (application == null) {
      setState(() => _error = 'Choose your dates on the calendar.');
      return;
    }
    if (application.reason.isEmpty) {
      setState(() => _reasonError = 'Give a reason for your request.');
      return;
    }
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(leaveApiProvider);
      final toast = ref.read(toastProvider.notifier);
      final id = await api.apply(application, session.user.id);
      // The list is now stale; drop it so returning shows the new request.
      ref.invalidate(leaveOverviewProvider);
      toast.show(
        'Leave requested · waiting for approval',
        onUndo: id == null
            ? null
            : () async {
                try {
                  await api.withdraw(id);
                  toast.show('Request withdrawn');
                } on ApiFailure {
                  toast.show('Could not withdraw — cancel it from Leave');
                }
                ref.invalidate(leaveOverviewProvider);
              },
      );
      if (mounted) context.pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        if (failure is ApiValidation) {
          _reasonError = failure.forField('description');
          _error = _reasonError == null ? failure.message : null;
        } else {
          _error = failure.message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(leaveOverviewProvider).value;
    final balances = overview?.balances ?? const <LeaveBalance>[];
    final holidays = overview?.holidays ?? const <Holiday>[];
    _selected ??= balances.isEmpty ? null : balances.first;
    final application = _application;
    final single = _start != null && (_end == null || _end == _start);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(title: 'Apply for leave', onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.x6,
                AppSpace.screen,
                AppSpace.scrollBottom,
              ),
              children: [
                if (_error != null) ...[
                  _ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpace.x14),
                ],

                const _Heading('Leave type'),
                const SizedBox(height: AppSpace.x10),
                _TypeGrid(
                  balances: balances,
                  selected: _selected,
                  onSelect: (b) => setState(() => _selected = b),
                ),

                const SizedBox(height: AppSpace.x20),
                Row(
                  children: [
                    const Expanded(child: _Heading('Dates')),
                    Flexible(
                      // Align, or the value sits at the start of its half of the row:
                      // an Expanded label and a Flexible value split the width evenly.
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          'Tap a start day, then an end day',
                          textAlign: TextAlign.end,
                          style: AppText.meta.copyWith(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x10),
                _RangeCalendar(
                  start: _start,
                  end: _end,
                  holidays: holidays,
                  onPick: _pickDay,
                ),

                if (_start != null) ...[
                  const SizedBox(height: AppSpace.x12),
                  if (single)
                    _PartChips(
                      label: null,
                      value: _startBreakdown,
                      onChanged: (v) => setState(() => _startBreakdown = v),
                    )
                  else ...[
                    _PartChips(
                      label: 'First day',
                      value: _startBreakdown,
                      onChanged: (v) => setState(() => _startBreakdown = v),
                    ),
                    const SizedBox(height: AppSpace.x8),
                    _PartChips(
                      label: 'Last day',
                      value: _endBreakdown,
                      onChanged: (v) => setState(() => _endBreakdown = v),
                    ),
                  ],
                ],

                const SizedBox(height: AppSpace.x12),
                _SummaryCard(
                  application: application,
                  balance: _selected,
                  holidays: holidays,
                ),

                const SizedBox(height: AppSpace.x12),
                AppCard(
                  borderColor: _reasonError == null
                      ? AppColors.cardBorder
                      : AppColors.danger,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel('Reason'),
                      TextField(
                        controller: _reason,
                        minLines: 2,
                        maxLines: 5,
                        style: AppText.body.copyWith(fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 8),
                          hintText: 'Why are you taking this leave?',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_reasonError != null) ...[
                  const SizedBox(height: AppSpace.x6),
                  Text(
                    _reasonError!,
                    style: AppText.meta.copyWith(color: AppColors.danger),
                  ),
                ],

                const SizedBox(height: AppSpace.x20),
                AppButton(
                  label: _busy ? 'Submitting…' : 'Submit request',
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: AppText.cardTitle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// Two-column radio cards, one per leave type the person holds.
class _TypeGrid extends StatelessWidget {
  const _TypeGrid({
    required this.balances,
    required this.selected,
    required this.onSelect,
  });

  final List<LeaveBalance> balances;
  final LeaveBalance? selected;
  final ValueChanged<LeaveBalance> onSelect;

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return Text(
        'No leave types are assigned to you yet.',
        style: AppText.body,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpace.x10;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final b in balances)
              SizedBox(
                width: width,
                child: _TypeCard(
                  balance: b,
                  selected: selected?.id == b.id,
                  onTap: () => onSelect(b),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.balance,
    required this.selected,
    required this.onTap,
  });

  final LeaveBalance balance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = balance.totalDays;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label:
          '${balance.type.name}, ${formatDays(days)} '
          '${days == 1 ? 'day' : 'days'} available',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTint : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.brandStrong : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? null : AppShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balance.type.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle.copyWith(
                        fontSize: 13.5,
                        color: selected
                            ? AppColors.brandTintInk
                            : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatDays(days)} ${days == 1 ? 'day' : 'days'} '
                      'available',
                      style: AppText.meta.copyWith(
                        color: selected
                            ? AppColors.brandTintInk
                            : AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.x6),
              _Radio(on: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? AppColors.brandStrong : AppColors.line3,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: on
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.brandStrong,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

/// A month grid with tap-start / tap-end range selection.
class _RangeCalendar extends StatefulWidget {
  const _RangeCalendar({
    required this.start,
    required this.end,
    required this.holidays,
    required this.onPick,
  });

  final DateTime? start;
  final DateTime? end;
  final List<Holiday> holidays;
  final ValueChanged<DateTime> onPick;

  @override
  State<_RangeCalendar> createState() => _RangeCalendarState();
}

class _RangeCalendarState extends State<_RangeCalendar> {
  late DateTime _month = () {
    final base = widget.start ?? DateTime.now();
    return DateTime(base.year, base.month);
  }();

  // Leave can be backdated in Horilla, so a year back; two years ahead.
  late final DateTime _first = () {
    final n = DateTime.now();
    return DateTime(n.year - 1, n.month);
  }();
  late final DateTime _last = () {
    final n = DateTime.now();
    return DateTime(n.year + 2, n.month);
  }();

  String? _holidayOn(DateTime day) {
    for (final h in widget.holidays) {
      final d = h.startDate;
      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        return h.name;
      }
    }
    return null;
  }

  void _shift(int months) {
    final next = DateTime(_month.year, _month.month + months);
    if (next.isBefore(_first) || next.isAfter(_last)) return;
    setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = DateTime(_month.year, _month.month).weekday - 1; // Mon = 0
    final start = widget.start;
    final end = widget.end ?? widget.start;
    final today = DateTime.now();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              _ArrowButton(
                icon: Icons.chevron_left,
                label: 'Previous month',
                onTap: () => _shift(-1),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_month),
                  textAlign: TextAlign.center,
                  style: AppText.cardTitle.copyWith(fontSize: 14.5),
                ),
              ),
              _ArrowButton(
                icon: Icons.chevron_right,
                label: 'Next month',
                onTap: () => _shift(1),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.x6),
          Row(
            children: [
              for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: AppText.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.ink4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.x6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // Explicit: with none, the grid applies the status-bar inset it
            // inherits, which drew a blank band above the first week.
            padding: EdgeInsets.zero,
            // Wider than tall, as the handoff draws it; square cells made the
            // month taller than the screen.
            childAspectRatio: 1.25,
            mainAxisSpacing: 2,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var n = 1; n <= daysInMonth; n++)
                () {
                  final day = DateTime(_month.year, _month.month, n);
                  final isEnd =
                      start != null &&
                      (day == start || (end != null && day == end));
                  final inRange =
                      start != null &&
                      end != null &&
                      day.isAfter(start) &&
                      day.isBefore(end);
                  final holiday = _holidayOn(day);
                  final isToday =
                      day.year == today.year &&
                      day.month == today.month &&
                      day.day == today.day;
                  return _DayCell(
                    day: n,
                    date: day,
                    isEnd: isEnd,
                    inRange: inRange,
                    isToday: isToday,
                    holiday: holiday,
                    onTap: () => widget.onPick(day),
                  );
                }(),
            ],
          ),
          if (widget.holidays.any(
            (h) =>
                h.startDate.year == _month.year &&
                h.startDate.month == _month.month,
          )) ...[
            const SizedBox(height: AppSpace.x6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpace.x6),
                Text(
                  'holiday',
                  style: AppText.mono.copyWith(
                    fontSize: 10,
                    color: AppColors.ink3,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Pressable(
      onTap: onTap,
      child: SizedBox(
        width: kMinHitTarget,
        height: kMinHitTarget,
        child: Icon(icon, color: AppColors.ink2),
      ),
    ),
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.date,
    required this.isEnd,
    required this.inRange,
    required this.isToday,
    required this.holiday,
    required this.onTap,
  });

  final int day;
  final DateTime date;
  final bool isEnd;
  final bool inRange;
  final bool isToday;
  final String? holiday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isEnd
        ? AppColors.surface
        : inRange
        ? AppColors.brandTintInk
        : AppColors.ink;
    return Semantics(
      button: true,
      selected: isEnd || inRange,
      label:
          '${DateFormat('EEEE d MMMM').format(date)}'
          '${holiday == null ? '' : ', $holiday'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isEnd
                ? AppColors.brandStrong
                : inRange
                ? AppColors.brandTint
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isToday && !isEnd
                ? Border.all(color: AppColors.line3)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              MediaQuery.withClampedTextScaling(
                // Cells are a fixed seventh of the card; past 1.4x the
                // digits overrun them. The semantics label carries the date
                // at any size.
                maxScaleFactor: 1.4,
                child: Text(
                  '$day',
                  style: AppText.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: isEnd ? FontWeight.w800 : FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
              if (holiday != null)
                Positioned(
                  bottom: 5,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isEnd ? AppColors.surface : AppColors.brand,
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

class _PartChips extends StatelessWidget {
  const _PartChips({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String? label;
  final LeaveBreakdown value;
  final ValueChanged<LeaveBreakdown> onChanged;

  @override
  Widget build(BuildContext context) {
    // Label above, not beside: beside it, three chips no longer fit one line
    // and the third wrapped under the label.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.meta),
          const SizedBox(height: AppSpace.x6),
        ],
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final option in LeaveBreakdown.values)
              Semantics(
                button: true,
                selected: option == value,
                label: '${label ?? 'Day'}: ${option.label}',
                excludeSemantics: true,
                child: Pressable(
                  onTap: () => onChanged(option),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: option == value
                          ? AppColors.ink
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                      border: Border.all(
                        color: option == value ? AppColors.ink : AppColors.line,
                      ),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        option.label,
                        style: AppText.meta.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: option == value
                              ? AppColors.surface
                              : AppColors.ink2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The dark live summary: range, estimated days, balance after.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.application,
    required this.balance,
    required this.holidays,
  });

  final LeaveApplication? application;
  final LeaveBalance? balance;
  final List<Holiday> holidays;

  @override
  Widget build(BuildContext context) {
    final a = application;
    final b = balance;

    final String range;
    final String days;
    final String? after;
    final String note;
    var warn = false;

    if (a == null) {
      range = 'No dates yet';
      days = '—';
      after = null;
      note = 'Pick dates on the calendar to see the estimate.';
    } else {
      final fmt = DateFormat('d MMM');
      range = a.startDate == a.endDate
          ? DateFormat('EEE, d MMM').format(a.startDate)
          : '${fmt.format(a.startDate)} – ${fmt.format(a.endDate)}';
      final estimate = a.estimatedDays;
      days =
          'About ${formatDays(estimate)} '
          '${estimate == 1 ? 'day' : 'days'}';
      final left = b == null ? null : b.totalDays - estimate;
      after = left == null ? null : formatDays(left < 0 ? 0 : left);
      final crossed = [
        for (final h in holidays)
          if (!h.startDate.isBefore(a.startDate) &&
              !h.startDate.isAfter(a.endDate))
            '${h.name} (${fmt.format(h.startDate)})',
      ];
      if (left != null && left < 0) {
        warn = true;
        note =
            'More than your ${formatDays(b!.totalDays)}-day balance — '
            'the server may refuse it.';
      } else if (crossed.isNotEmpty) {
        note =
            '${crossed.join(' and ')} falls in this range — your leave '
            'policy decides whether it counts.';
      } else {
        note =
            'Weekends and holidays are counted by your company\'s '
            'policy; the server confirms the final number.';
      }
    }

    return Semantics(
      liveRegion: true,
      label:
          '$range. $days.${after == null ? '' : ' Balance after $after.'} '
          '$note',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        range.toUpperCase(),
                        style: AppText.eyebrow.copyWith(
                          color: AppColors.onDark2,
                        ),
                      ),
                      const SizedBox(height: AppSpace.x6),
                      Text(
                        days,
                        style: AppText.statValue.copyWith(
                          fontSize: 22,
                          color: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (after != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Balance after',
                        style: AppText.meta.copyWith(
                          fontSize: 11,
                          color: AppColors.onDark2,
                        ),
                      ),
                      Text(
                        after,
                        style: AppText.mono.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: warn
                              ? AppColors.toastAction
                              : AppColors.surface,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.x12),
            const Divider(height: 1, color: AppColors.onDarkLine),
            const SizedBox(height: AppSpace.x12),
            Text(
              note,
              style: AppText.meta.copyWith(
                color: warn ? AppColors.toastAction : AppColors.onDark2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.x12),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          border: Border.all(color: AppColors.dangerBorder),
        ),
        child: Text(
          message,
          style: AppText.body.copyWith(color: AppColors.danger),
        ),
      ),
    );
  }
}
