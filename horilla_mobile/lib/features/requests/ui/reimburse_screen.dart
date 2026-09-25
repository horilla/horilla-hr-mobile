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
import '../../../shared/widgets/toast.dart';
import '../data/request_models.dart';
import '../data/requests_api.dart';

/// Screen 12 of the handoff: an expense claim.
///
/// No receipt capture in this pass. `attachment` is a nullable field
/// server-side, so a claim without one is a complete, valid request, not a
/// partial one -- and camera/file-picker access is a real dependency and a
/// permission prompt to add for a screen that works without it. Add
/// `image_picker` here when a receipt is actually asked for.
class ReimburseScreen extends ConsumerStatefulWidget {
  const ReimburseScreen({super.key});

  @override
  ConsumerState<ReimburseScreen> createState() => _ReimburseScreenState();
}

class _ReimburseScreenState extends ConsumerState<ReimburseScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  DateTime _incurredOn = DateTime.now();

  bool _busy = false;
  String? _error;
  String? _titleError;
  String? _amountError;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incurredOn,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _incurredOn = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _titleError = null;
      _amountError = null;
    });

    final session = ref.read(sessionProvider);
    if (session == null) return;

    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Say what this is for.');
      return;
    }
    // The numeric keypad follows the device locale, so some users can only
    // type a comma as the decimal separator.
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter the amount you paid.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(requestsApiProvider)
          .submitReimbursement(
            ReimbursementDraft(
              title: title,
              amount: amount,
              incurredOn: _incurredOn,
            ),
            session.user.id,
          );
      ref.invalidate(requestInboxProvider);
      ref.read(toastProvider.notifier).show('Reimbursement claim submitted');
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
          AppTopBar(title: 'Reimbursement claim', onBack: () => context.pop()),
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

                AppCard(
                  borderColor: _titleError == null
                      ? AppColors.cardBorder
                      : AppColors.danger,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel('What is it for'),
                      TextField(
                        controller: _title,
                        style: AppText.body.copyWith(fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 8),
                          hintText: 'Client dinner, taxi, supplies…',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_titleError != null) ...[
                  const SizedBox(height: AppSpace.x6),
                  Text(
                    _titleError!,
                    style: AppText.meta.copyWith(color: AppColors.danger),
                  ),
                ],

                const SizedBox(height: AppSpace.x14),
                AppCard(
                  borderColor: _amountError == null
                      ? AppColors.cardBorder
                      : AppColors.danger,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel('Amount'),
                      const SizedBox(height: AppSpace.x6),
                      TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppText.statValue.copyWith(fontSize: 22),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_amountError != null) ...[
                  const SizedBox(height: AppSpace.x6),
                  Text(
                    _amountError!,
                    style: AppText.meta.copyWith(color: AppColors.danger),
                  ),
                ],

                const SizedBox(height: AppSpace.x14),
                AppCard(
                  onTap: _pickDate,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const EyebrowLabel('Date incurred'),
                      Text(
                        DateFormat('EEE d MMM yyyy').format(_incurredOn),
                        style: AppText.cardTitle.copyWith(
                          fontSize: 14,
                          color: AppColors.brandStrong,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.x20),
                AppButton(
                  label: _busy ? 'Submitting…' : 'Submit claim',
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
