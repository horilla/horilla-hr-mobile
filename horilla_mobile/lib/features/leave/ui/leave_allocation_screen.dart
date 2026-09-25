import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Asking HR to add days to a leave balance.
class LeaveAllocationScreen extends ConsumerStatefulWidget {
  const LeaveAllocationScreen({super.key});

  @override
  ConsumerState<LeaveAllocationScreen> createState() =>
      _LeaveAllocationScreenState();
}

class _LeaveAllocationScreenState extends ConsumerState<LeaveAllocationScreen> {
  final _reason = TextEditingController();
  LeaveBalance? _selected;
  double _days = 1;
  bool _busy = false;
  String? _error;
  String? _reasonError;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final selected = _selected;
    final session = ref.read(sessionProvider);

    setState(() {
      _error = null;
      _reasonError = null;
    });

    if (selected == null) {
      setState(() => _error = 'Choose a leave type.');
      return;
    }

    final request = LeaveAllocationRequest(
      leaveTypeId: selected.type.id,
      requestedDays: _days,
      reason: _reason.text,
    );

    if (!request.isValid) {
      setState(() => _reasonError = 'Say why you need these days.');
      return;
    }
    if (session == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(leaveApiProvider)
          .requestAllocation(request, session.user.id);
      ref.invalidate(leaveOverviewProvider);
      ref
          .read(toastProvider.notifier)
          .show(
            'Sent to HR · ${formatDays(_days)} '
            '${_days == 1 ? 'day' : 'days'} requested',
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
    final balances = ref.watch(leaveOverviewProvider).value?.balances ?? [];
    // Preselected, as the handoff draws it and as the apply form does.
    _selected ??= balances.isEmpty ? null : balances.first;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(title: 'Allocation request', onBack: () => context.pop()),
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
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const EyebrowLabel('Days requested'),
                                const SizedBox(height: AppSpace.x6),
                                Text(
                                  _days == _days.roundToDouble()
                                      ? _days.toStringAsFixed(0)
                                      : _days.toStringAsFixed(1),
                                  style: AppText.statValue.copyWith(
                                    fontSize: 26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _Stepper(
                            icon: Icons.remove,
                            label: 'Fewer days',
                            // Half-day steps, and never below half a day: a
                            // request for zero days is not a request.
                            onTap: _days > 0.5
                                ? () => setState(() => _days -= 0.5)
                                : null,
                          ),
                          const SizedBox(width: AppSpace.x8),
                          _Stepper(
                            icon: Icons.add,
                            label: 'More days',
                            onTap: () => setState(() => _days += 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.x14),
                      const Divider(height: 1, color: AppColors.line2),
                      const SizedBox(height: AppSpace.x12),
                      // Stated up front: this goes to HR, not to a manager,
                      // and someone waiting on the wrong person is a support
                      // ticket waiting to happen.
                      Text(
                        _selected == null
                            ? 'Approved by HR, not your manager.'
                            : 'Current balance '
                                  '${formatDays(_selected!.totalDays)} days · '
                                  'approved by HR, not your manager.',
                        style: AppText.meta.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
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
                          hintText: 'Why do you need these extra days?',
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
                  label: _busy ? 'Submitting…' : 'Submit to HR',
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

class _Stepper extends StatelessWidget {
  const _Stepper({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: kMinHitTarget,
          height: kMinHitTarget,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.ink : AppColors.ink4,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x14),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTint : AppColors.bg2,
            borderRadius: BorderRadius.circular(AppRadii.field),
            border: Border.all(
              color: selected ? AppColors.brandTint : AppColors.line,
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppText.body.copyWith(
                fontSize: 13.5,
                color: selected ? AppColors.brandTintInk : AppColors.ink,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
