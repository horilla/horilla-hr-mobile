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
import '../data/payroll_api.dart';
import '../data/payroll_models.dart';

class PayslipDetailScreen extends ConsumerWidget {
  const PayslipDetailScreen({super.key, required this.payslipId});

  final int payslipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslip = ref.watch(payslipProvider(payslipId));
    final symbol = ref.watch(currencySymbolProvider);

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
                Text('Payslip', style: AppText.appBarTitle),
              ],
            ),
          ),
          Expanded(child: _body(ref, payslip, symbol)),
        ],
      ),
    );
  }

  Widget _body(
    WidgetRef ref,
    AsyncValue<PayslipDetail> payslip,
    String? symbol,
  ) {
    final data = payslip.value;
    if (data != null) return _DetailBody(detail: data, symbol: symbol);

    final error = payslip.error;
    if (error != null) {
      return ErrorStateCard(
        failure: error is ApiFailure ? error : const ApiUnknown(),
        onRetry: () => ref.invalidate(payslipProvider(payslipId)),
      );
    }
    return const _DetailSkeleton();
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.symbol});

  final PayslipDetail detail;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    final summary = detail.summary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x18,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EyebrowLabel(
                '${DateFormat('d MMM').format(summary.startDate)} – '
                '${DateFormat('d MMM yyyy').format(summary.endDate)}',
              ),
              const SizedBox(height: AppSpace.x10),
              Text(
                Money(summary.netPay, symbol: symbol).formatted,
                style: AppText.heroNumber,
              ),
              const SizedBox(height: AppSpace.x6),
              Text('Net pay', style: AppText.meta),
            ],
          ),
        ),

        if (detail.earnings.isNotEmpty) ...[
          const SizedBox(height: AppSpace.x16),
          _ComponentCard(
            label: 'Earnings',
            labelColor: AppColors.success,
            components: detail.earnings,
            total: summary.grossPay,
            totalLabel: 'Gross pay',
            symbol: symbol,
          ),
        ],

        if (detail.deductions.isNotEmpty) ...[
          const SizedBox(height: AppSpace.x12),
          _ComponentCard(
            label: 'Deductions',
            labelColor: AppColors.danger,
            components: detail.deductions,
            total: summary.deduction,
            totalLabel: 'Total deductions',
            symbol: symbol,
          ),
        ],

        const SizedBox(height: AppSpace.x16),
        Text(
          'Paid days are derived from your hour account. If something looks '
          'wrong, raise it with payroll through the helpdesk rather than '
          'here.',
          style: AppText.meta,
        ),
      ],
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({
    required this.label,
    required this.labelColor,
    required this.components,
    required this.total,
    required this.totalLabel,
    required this.symbol,
  });

  final String label;
  final Color labelColor;
  final List<PayComponent> components;
  final double total;
  final String totalLabel;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EyebrowLabel(label, color: labelColor),
          const SizedBox(height: AppSpace.x12),
          for (final component in components)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.x10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(component.title, style: AppText.body),
                  ),
                  Text(
                    Money(component.amount, symbol: symbol).formatted,
                    style: AppText.mono.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
          const Divider(height: AppSpace.x12, color: AppColors.line2),
          Row(
            children: [
              Expanded(
                child: Text(
                  totalLabel,
                  style: AppText.cardTitle.copyWith(fontSize: 13.5),
                ),
              ),
              Text(
                Money(total, symbol: symbol).formatted,
                style: AppText.mono.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

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
        AppCard.skeleton(height: 130),
        SizedBox(height: AppSpace.x16),
        AppCard.skeleton(height: 180),
      ],
    );
  }
}
