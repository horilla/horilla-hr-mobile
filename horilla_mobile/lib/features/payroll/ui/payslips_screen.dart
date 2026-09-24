import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../data/payroll_api.dart';
import '../data/payroll_models.dart';
import '../../../shared/widgets/app_top_bar.dart';

class PayslipsScreen extends ConsumerWidget {
  const PayslipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslips = ref.watch(payslipsProvider);
    final symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(
            title: 'Payroll',
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandStrong,
              onRefresh: () async => ref.refresh(payslipsProvider.future),
              child: _body(ref, payslips, symbol),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    WidgetRef ref,
    AsyncValue<List<PayslipSummary>> payslips,
    String? symbol,
  ) {
    final data = payslips.value;
    if (data != null) return _PayslipsBody(payslips: data, symbol: symbol);

    final error = payslips.error;
    if (error != null) {
      return ErrorStateCard(
        failure: error is ApiFailure ? error : const ApiUnknown(),
        onRetry: () => ref.invalidate(payslipsProvider),
      );
    }
    return const _PayslipsSkeleton();
  }
}

class _PayslipsBody extends StatelessWidget {
  const _PayslipsBody({required this.payslips, required this.symbol});

  final List<PayslipSummary> payslips;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    if (payslips.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EyebrowLabel('No payslips yet'),
                const SizedBox(height: AppSpace.x8),
                Text(
                  'Payslips appear here once payroll has been run for you.',
                  style: AppText.body,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final latest = payslips.first;
    final earlier = payslips.skip(1).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x18,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        _LatestPayslipHero(payslip: latest, symbol: symbol),
        if (earlier.isNotEmpty) ...[
          const SizedBox(height: AppSpace.x20),
          const SectionHeader(title: 'Earlier payslips'),
          const SizedBox(height: AppSpace.x12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < earlier.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.line2),
                  _PayslipRow(payslip: earlier[i], symbol: symbol),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LatestPayslipHero extends StatelessWidget {
  const _LatestPayslipHero({required this.payslip, required this.symbol});

  final PayslipSummary payslip;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/requests/payslips/${payslip.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.x20),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadii.hero),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LATEST · ${DateFormat('MMMM yyyy').format(payslip.endDate).toUpperCase()}',
              style: AppText.eyebrow.copyWith(color: AppColors.onDark2),
            ),
            const SizedBox(height: AppSpace.x12),
            Text(
              Money(payslip.netPay, symbol: symbol).formatted,
              style: AppText.heroNumber.copyWith(color: AppColors.surface),
            ),
            const SizedBox(height: AppSpace.x4),
            Text(
              payslip.bankLast4 == null
                  ? 'Net pay'
                  : 'Net pay · ••${payslip.bankLast4}',
              style: AppText.meta.copyWith(color: AppColors.onDark2),
            ),
            const SizedBox(height: AppSpace.x18),
            Row(
              children: [
                Expanded(
                  child: _InsetTile(
                    label: 'Gross',
                    value: Money(payslip.grossPay, symbol: symbol).formatted,
                  ),
                ),
                const SizedBox(width: AppSpace.x10),
                Expanded(
                  child: _InsetTile(
                    label: 'Deductions',
                    value: Money(payslip.deduction, symbol: symbol).formatted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsetTile extends StatelessWidget {
  const _InsetTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.x12),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppText.eyebrow.copyWith(color: AppColors.onDark2),
          ),
          const SizedBox(height: AppSpace.x6),
          Text(
            value,
            style: AppText.mono.copyWith(
              color: AppColors.surface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayslipRow extends StatelessWidget {
  const _PayslipRow({required this.payslip, required this.symbol});

  final PayslipSummary payslip;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/requests/payslips/${payslip.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16,
          vertical: AppSpace.x14,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(payslip.endDate),
                    style: AppText.cardTitle.copyWith(fontSize: 14),
                  ),
                  if (payslip.daysLine != null) ...[
                    const SizedBox(height: 2),
                    Text(payslip.daysLine!, style: AppText.meta),
                  ],
                ],
              ),
            ),
            Text(
              Money(payslip.netPay, symbol: symbol).formatted,
              style: AppText.mono.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpace.x6),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.ink4),
          ],
        ),
      ),
    );
  }
}

class _PayslipsSkeleton extends StatelessWidget {
  const _PayslipsSkeleton();

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
        AppCard.skeleton(height: 180),
        SizedBox(height: AppSpace.x20),
        AppCard.skeleton(height: 160),
      ],
    );
  }
}
