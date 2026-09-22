import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../data/leave_api.dart';
import '../data/leave_models.dart';

/// Screen 6 of the handoff, and the first screen in the app that writes.
class LeaveApplyScreen extends ConsumerStatefulWidget {
  const LeaveApplyScreen({super.key});

  @override
  ConsumerState<LeaveApplyScreen> createState() => _LeaveApplyScreenState();
}

class _LeaveApplyScreenState extends ConsumerState<LeaveApplyScreen> {
  final _reason = TextEditingController();

  LeaveBalance? _selected;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
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
    if (selected == null) return null;
    return LeaveApplication(
      leaveTypeId: selected.type.id,
      startDate: _start,
      endDate: _end,
      startBreakdown: _startBreakdown,
      endBreakdown: _endBreakdown,
      reason: _reason.text.trim(),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _start = picked;
        // Keeping end >= start here means the form cannot express a range the
        // server would only reject after a round trip.
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked.isBefore(_start) ? _start : picked;
      }
    });
  }

  Future<void> _submit() async {
    final application = _application;
    final session = ref.read(sessionProvider);

    setState(() {
      _error = null;
      _reasonError = null;
    });

    if (application == null) {
      setState(() => _error = 'Choose a leave type.');
      return;
    }
    if (application.reason.isEmpty) {
      setState(() => _reasonError = 'Give a reason for your request.');
      return;
    }
    if (session == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(leaveApiProvider).apply(application, session.user.id);
      // The list is now stale; drop it so returning shows the new request.
      ref.invalidate(leaveOverviewProvider);
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
    final balances = ref.watch(leaveOverviewProvider).value?.balances ?? [];
    final application = _application;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: PlatformChrome.appBarPadding,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const SizedBox(
                    width: kMinHitTarget,
                    height: 28,
                    child: Icon(Icons.chevron_left, color: AppColors.ink),
                  ),
                ),
                Text('Apply for leave', style: AppText.appBarTitle),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.x18,
                AppSpace.screen,
                AppSpace.scrollBottom,
              ),
              children: [
                if (_error != null) ...[
                  _ErrorBanner(message: _error!),
                  const SizedBox(height: AppSpace.x14),
                ],

                const EyebrowLabel('Leave type'),
                const SizedBox(height: AppSpace.x10),
                Wrap(
                  spacing: AppSpace.x8,
                  runSpacing: AppSpace.x8,
                  children: [
                    for (final balance in balances)
                      _Chip(
                        label: balance.type.name,
                        selected: _selected?.id == balance.id,
                        onTap: () => setState(() => _selected = balance),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpace.x18),
                AppCard(
                  child: Column(
                    children: [
                      _DateRow(
                        label: 'From',
                        date: _start,
                        breakdown: _startBreakdown,
                        onPickDate: () => _pickDate(isStart: true),
                        onBreakdown: (value) =>
                            setState(() => _startBreakdown = value),
                      ),
                      const Divider(height: AppSpace.x20, color: AppColors.line2),
                      _DateRow(
                        label: 'To',
                        date: _end,
                        breakdown: _endBreakdown,
                        onPickDate: () => _pickDate(isStart: false),
                        onBreakdown: (value) =>
                            setState(() => _endBreakdown = value),
                      ),
                    ],
                  ),
                ),

                if (application != null) ...[
                  const SizedBox(height: AppSpace.x10),
                  _DaysPreview(
                    application: application,
                    balance: _selected!,
                  ),
                ],

                const SizedBox(height: AppSpace.x18),
                const EyebrowLabel('Reason'),
                const SizedBox(height: AppSpace.x10),
                AppCard(
                  borderColor:
                      _reasonError == null ? AppColors.line : AppColors.danger,
                  child: TextField(
                    controller: _reason,
                    maxLines: 4,
                    style: AppText.body,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Why are you taking this leave?',
                    ),
                  ),
                ),
                if (_reasonError != null) ...[
                  const SizedBox(height: AppSpace.x6),
                  Text(
                    _reasonError!,
                    style: AppText.meta.copyWith(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.screen),
              child: AppButton(
                label: _busy ? 'Submitting…' : 'Submit request',
                onPressed: _busy ? null : _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// How many days this costs, and what is left.
///
/// Says "about" deliberately: weekends, company off-days and holidays are
/// excluded by the server, which owns the calendar. Presenting a client-side
/// count as exact would be confidently wrong whenever a request spans a
/// weekend.
class _DaysPreview extends StatelessWidget {
  const _DaysPreview({required this.application, required this.balance});

  final LeaveApplication application;
  final LeaveBalance balance;

  @override
  Widget build(BuildContext context) {
    final days = application.estimatedDays;
    final remaining = balance.totalDays - days;
    final short = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(AppSpace.x12),
      decoration: BoxDecoration(
        color: short ? AppColors.dangerBg : AppColors.bg2,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(
          color: short ? AppColors.dangerBorder : AppColors.line,
        ),
      ),
      child: Text(
        short
            ? 'About ${_days(days)} requested — more than your '
                '${_days(balance.totalDays)} balance.'
            : 'About ${_days(days)} requested · '
                '${_days(remaining)} left after this',
        style: AppText.meta.copyWith(
          color: short ? AppColors.danger : AppColors.ink3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _days(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text ${value == 1 ? 'day' : 'days'}';
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    required this.breakdown,
    required this.onPickDate,
    required this.onBreakdown,
  });

  final String label;
  final DateTime date;
  final LeaveBreakdown breakdown;
  final VoidCallback onPickDate;
  final ValueChanged<LeaveBreakdown> onBreakdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            EyebrowLabel(label),
            GestureDetector(
              onTap: onPickDate,
              child: Text(
                DateFormat('EEE d MMM yyyy').format(date),
                style: AppText.cardTitle.copyWith(
                  fontSize: 14,
                  color: AppColors.brandStrong,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.x10),
        Wrap(
          spacing: AppSpace.x6,
          children: [
            for (final option in LeaveBreakdown.values)
              _Chip(
                label: option.label,
                selected: option == breakdown,
                onTap: () => onBreakdown(option),
                compact: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpace.x10 : AppSpace.x14,
            vertical: compact ? AppSpace.x6 : AppSpace.x10,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTint : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(
              color: selected ? AppColors.brandTintBorder : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: AppText.meta.copyWith(
              color: selected ? AppColors.brandTintInk : AppColors.ink2,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.x12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Text(
        message,
        style: AppText.body.copyWith(color: AppColors.danger),
      ),
    );
  }
}
