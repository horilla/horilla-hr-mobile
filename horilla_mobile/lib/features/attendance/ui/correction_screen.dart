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
import '../data/attendance_api.dart';
import '../data/attendance_models.dart';
import '../data/correction_models.dart';

/// Asking for a day's times to be corrected.
///
/// Reached from a day in the activity log, so the day itself is already
/// chosen -- this screen only edits its times and asks why.
class CorrectionScreen extends ConsumerStatefulWidget {
  const CorrectionScreen({super.key, required this.day});

  final AttendanceDay day;

  @override
  ConsumerState<CorrectionScreen> createState() => _CorrectionScreenState();
}

class _CorrectionScreenState extends ConsumerState<CorrectionScreen> {
  late final _clockIn = TextEditingController(text: widget.day.clockIn ?? '');
  late final _clockOut =
      TextEditingController(text: widget.day.clockOut ?? '');
  final _reason = TextEditingController();

  Map<String, dynamic>? _original;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _reasonError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _clockIn.dispose();
    _clockOut.dispose();
    _reason.dispose();
    super.dispose();
  }

  /// The full row carries shift and work type, which the server's form
  /// requires even though a correction is not changing them.
  Future<void> _load() async {
    try {
      final day = await ref.read(attendanceApiProvider).fetchDay(widget.day.id);
      if (mounted) setState(() => _original = day);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _idFrom(Object? value) => switch (value) {
        final int id => id,
        final Map map => map['id'] is int ? map['id'] as int : null,
        _ => null,
      };

  Future<void> _submit() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;

    setState(() {
      _error = null;
      _reasonError = null;
    });

    final correction = AttendanceCorrection(
      attendanceId: widget.day.id,
      employeeId: session.user.id,
      attendanceDate: widget.day.date,
      clockIn: _clockIn.text.trim(),
      clockOut: _clockOut.text.trim(),
      reason: _reason.text,
      shiftId: _idFrom(_original?['shift_id']),
      workTypeId: _idFrom(_original?['work_type_id']),
    );

    if (correction.clockIn.isEmpty) {
      setState(() => _error = 'Enter the time you started.');
      return;
    }
    if (!correction.isValid) {
      setState(() => _reasonError = 'Say what needs correcting and why.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(attendanceApiProvider).requestCorrection(correction);
      ref.invalidate(attendanceOverviewProvider);
      if (mounted) context.pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        if (failure is ApiValidation) {
          _reasonError = failure.forField('request_description');
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: PlatformChrome.appBarPaddingOf(context),
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
                Text('Request correction', style: AppText.appBarTitle),
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
                  AppCard(
                    background: AppColors.dangerBg,
                    borderColor: AppColors.dangerBorder,
                    padding: const EdgeInsets.all(AppSpace.x12),
                    child: Text(
                      _error!,
                      style: AppText.body.copyWith(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: AppSpace.x14),
                ],

                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel('Day'),
                      const SizedBox(height: AppSpace.x6),
                      Text(
                        DateFormat('EEEE d MMMM yyyy').format(widget.day.date),
                        style: AppText.cardTitle.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.x14),
                Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: 'Started',
                        controller: _clockIn,
                      ),
                    ),
                    const SizedBox(width: AppSpace.x10),
                    Expanded(
                      child: _TimeField(
                        label: 'Finished',
                        controller: _clockOut,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.x6),
                Text(
                  'Use 24-hour times, for example 09:05. Leave the finish '
                  'time empty if the day is still open.',
                  style: AppText.meta,
                ),

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
                      hintText: 'What is wrong with this day?',
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

                const SizedBox(height: AppSpace.x12),
                Text(
                  'Your manager reviews corrections. The day is unchanged '
                  'until they approve it.',
                  style: AppText.meta,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.screen),
              child: AppButton(
                label: _busy ? 'Submitting…' : 'Request correction',
                onPressed: _busy || _loading ? null : _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x14,
        vertical: AppSpace.x10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EyebrowLabel(label),
          const SizedBox(height: AppSpace.x4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.datetime,
            style: AppText.mono.copyWith(fontSize: 15),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '09:00',
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
