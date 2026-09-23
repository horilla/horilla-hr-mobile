import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../data/leave_api.dart';
import '../data/leave_models.dart';

/// Asking HR to add days to a leave balance.
class LeaveAllocationScreen extends ConsumerStatefulWidget {
  const LeaveAllocationScreen({super.key});

  @override
  ConsumerState<LeaveAllocationScreen> createState() =>
      _LeaveAllocationScreenState();
}

class _LeaveAllocationScreenState
    extends ConsumerState<LeaveAllocationScreen> {
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
                Text('Request more days', style: AppText.appBarTitle),
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

                // Stated up front: the handoff notes this goes to HR, not to
                // a manager, and someone waiting on the wrong person is a
                // support ticket waiting to happen.
                AppCard(
                  background: AppColors.infoBg,
                  borderColor: AppColors.infoBorder,
                  padding: const EdgeInsets.all(AppSpace.x12),
                  child: Text(
                    'This asks HR to add days to your balance. It is not a '
                    'request for time off, and your manager does not approve '
                    'it.',
                    style: AppText.meta.copyWith(color: AppColors.infoInk),
                  ),
                ),

                const SizedBox(height: AppSpace.x18),
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
                  child: Row(
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
                              style: AppText.statValue,
                            ),
                          ],
                        ),
                      ),
                      _Stepper(
                        icon: Icons.remove,
                        // Half-day steps, and never below half a day: a
                        // request for zero days is not a request.
                        onTap: _days > 0.5
                            ? () => setState(() => _days -= 0.5)
                            : null,
                      ),
                      const SizedBox(width: AppSpace.x8),
                      _Stepper(
                        icon: Icons.add,
                        onTap: () => setState(() => _days += 0.5),
                      ),
                    ],
                  ),
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
                      hintText: 'Why do you need these extra days?',
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
                label: _busy ? 'Submitting…' : 'Submit to HR',
                onPressed: _busy ? null : _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(AppRadii.button),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.ink : AppColors.ink4,
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x14,
            vertical: AppSpace.x10,
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
