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
import '../data/request_models.dart';
import '../data/requests_api.dart';

/// Screen 11 of the handoff: ask for a shift swap or a work-type change.
///
/// One screen for both, toggled by a segmented control, because the server
/// models them identically down to the field names -- only `shift_id` versus
/// `work_type_id` differs.
///
/// The handoff's "current assignment" block and roster-conflict warning are
/// not drawn here: both need `/employee/employee-work-information/` without
/// a pk, which 500s on the server today (`get() missing 1 required
/// positional argument: 'pk'` -- the route is registered for a list call the
/// view was never written to handle). Reported upstream; not worth blocking
/// a request form that works without it. What someone is on today is
/// something they already know when they open this screen.
class ShiftRequestScreen extends ConsumerStatefulWidget {
  const ShiftRequestScreen({super.key});

  @override
  ConsumerState<ShiftRequestScreen> createState() => _ShiftRequestScreenState();
}

class _ShiftRequestScreenState extends ConsumerState<ShiftRequestScreen> {
  final _reason = TextEditingController();

  bool _forShift = true;
  RequestOption? _selected;
  DateTime _from = DateTime.now();
  DateTime? _till;
  bool _permanent = false;

  bool _busy = false;
  String? _error;
  String? _reasonError;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : (_till ?? _from);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_till != null && _till!.isBefore(_from)) _till = _from;
      } else {
        _till = picked;
      }
    });
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _reasonError = null;
    });

    final session = ref.read(sessionProvider);
    if (session == null) return;

    final selected = _selected;
    if (selected == null) {
      setState(
        () => _error = _forShift
            ? 'Choose a shift.'
            : 'Choose a work type.',
      );
      return;
    }
    // The server requires an end date unless the change is marked permanent
    // -- confirmed against the real endpoint, which otherwise rejects the
    // request with "Requested till field is required."
    if (!_permanent && _till == null) {
      setState(
        () => _error =
            'Choose an end date, or mark this as a permanent change.',
      );
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _reasonError = 'Give a reason for the change.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(requestsApiProvider).submitShiftOrWorkType(
        ShiftOrWorkTypeRequest(
          forShift: _forShift,
          requestedId: selected.id,
          previousId: null,
          requestedDate: _from,
          requestedTill: _permanent ? null : _till,
          reason: _reason.text.trim(),
        ),
        session.user.id,
      );
      ref.invalidate(requestInboxProvider);
      ref
          .read(toastProvider.notifier)
          .show(_forShift ? 'Shift change requested' : 'Work type change requested');
      if (mounted) context.pop(true);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
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
          AppTopBar(
            title: 'Shift / work type',
            onBack: () => context.pop(),
          ),
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

                _Segmented(
                  forShift: _forShift,
                  onChanged: (value) => setState(() {
                    _forShift = value;
                    _selected = null;
                  }),
                ),

                const SizedBox(height: AppSpace.x18),
                const EyebrowLabel('Requested'),
                const SizedBox(height: AppSpace.x10),
                _OptionChips(
                  forShift: _forShift,
                  selected: _selected,
                  onSelect: (option) => setState(() => _selected = option),
                ),

                const SizedBox(height: AppSpace.x18),
                AppCard(
                  child: Column(
                    children: [
                      _DateRow(
                        label: 'From',
                        date: _from,
                        onTap: () => _pickDate(isFrom: true),
                      ),
                      const Divider(height: AppSpace.x20, color: AppColors.line2),
                      Row(
                        children: [
                          Expanded(
                            child: Opacity(
                              opacity: _permanent ? 0.4 : 1,
                              child: _DateRow(
                                label: 'To',
                                date: _till,
                                placeholder: 'Open-ended',
                                onTap: _permanent
                                    ? null
                                    : () => _pickDate(isFrom: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpace.x20, color: AppColors.line2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Permanent change',
                              style: AppText.cardTitle.copyWith(fontSize: 14),
                            ),
                          ),
                          Switch(
                            value: _permanent,
                            activeThumbColor: AppColors.surface,
                            activeTrackColor: AppColors.brandStrong,
                            onChanged: (value) => setState(() {
                              _permanent = value;
                              if (value) _till = null;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.x18),
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
                          hintText: 'Why do you need this change?',
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

class _Segmented extends StatelessWidget {
  const _Segmented({required this.forShift, required this.onChanged});

  final bool forShift;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Row(
        children: [
          Expanded(child: _segment('Shift change', true)),
          const SizedBox(width: 4),
          Expanded(child: _segment('Work type', false)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool value) {
    final selected = forShift == value;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.field - 4),
            boxShadow: selected ? AppShadows.card : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.cardTitle.copyWith(
              fontSize: 13.5,
              color: selected ? AppColors.ink : AppColors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionChips extends ConsumerWidget {
  const _OptionChips({
    required this.forShift,
    required this.selected,
    required this.onSelect,
  });

  final bool forShift;
  final RequestOption? selected;
  final ValueChanged<RequestOption> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = forShift
        ? ref.watch(shiftOptionsProvider)
        : ref.watch(workTypeOptionsProvider);

    return options.when(
      data: (list) {
        if (list.isEmpty) {
          return Text(
            forShift ? 'No shifts are configured.' : 'No work types are configured.',
            style: AppText.body,
          );
        }
        return Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final option in list)
              Semantics(
                button: true,
                selected: selected?.id == option.id,
                label: option.name,
                excludeSemantics: true,
                child: Pressable(
                  onTap: () => onSelect(option),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.x14),
                    decoration: BoxDecoration(
                      color: selected?.id == option.id
                          ? AppColors.brandTint
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                      border: Border.all(
                        color: selected?.id == option.id
                            ? AppColors.brandTintBorder
                            : AppColors.line,
                      ),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        option.name,
                        style: AppText.meta.copyWith(
                          color: selected?.id == option.id
                              ? AppColors.brandTintInk
                              : AppColors.ink2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      error: (error, _) => Text(
        error is ApiFailure ? error.message : 'Could not load the options.',
        style: AppText.meta.copyWith(color: AppColors.danger),
      ),
      loading: () => const SizedBox(
        height: 40,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBar(width: 220, height: 36, radius: AppRadii.chip),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    this.placeholder = '—',
    this.onTap,
  });

  final String label;
  final DateTime? date;
  final String placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        EyebrowLabel(label),
        Semantics(
          button: onTap != null,
          label: '$label ${date == null ? placeholder : DateFormat('EEE d MMM yyyy').format(date!)}',
          excludeSemantics: true,
          child: Pressable(
            onTap: onTap,
            child: Text(
              date == null ? placeholder : DateFormat('EEE d MMM yyyy').format(date!),
              style: AppText.cardTitle.copyWith(
                fontSize: 14,
                color: onTap == null ? AppColors.ink4 : AppColors.brandStrong,
              ),
            ),
          ),
        ),
      ],
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
        child: Text(message, style: AppText.body.copyWith(color: AppColors.danger)),
      ),
    );
  }
}
