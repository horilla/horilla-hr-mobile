import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/scope.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../data/leave_api.dart';
import '../data/leave_models.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(leaveOverviewProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(
            title: 'Leave',
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/time'),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandStrong,
              onRefresh: () async => ref.refresh(leaveOverviewProvider.future),
              child: _body(ref, overview),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(WidgetRef ref, AsyncValue<LeaveOverview> overview) {
    final data = overview.value;
    if (data != null) return _LeaveBody(data: data);

    final error = overview.error;
    if (error != null) {
      return ErrorStateCard(
        failure: error is ApiFailure ? error : const ApiUnknown(),
        onRetry: () => ref.invalidate(leaveOverviewProvider),
      );
    }
    return const _LeaveSkeleton();
  }
}

class _LeaveBody extends StatelessWidget {
  const _LeaveBody({required this.data});

  final LeaveOverview data;

  @override
  Widget build(BuildContext context) {
    final carried = data.balances.fold<double>(
      0,
      (sum, b) => sum + b.carryforwardDays,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x6,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        if (data.balances.isEmpty)
          const _NoBalances()
        else
          _BalanceGrid(balances: data.balances),
        if (carried > 0) ...[
          const SizedBox(height: AppSpace.x10),
          Text(
            'Includes ${formatDays(carried)} carried-forward '
            '${carried == 1 ? 'day' : 'days'}, shown lighter on each ring.',
            style: AppText.meta,
          ),
        ],

        const SizedBox(height: AppSpace.x16),
        AppButton(
          label: 'Apply for leave',
          onPressed: () => context.push('/time/leave/apply'),
        ),
        const SizedBox(height: AppSpace.x12),
        AppCard(
          onTap: () => context.push('/time/leave/allocation'),
          padding: const EdgeInsets.all(AppSpace.x16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allocation request',
                      style: AppText.cardTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text('Ask HR for extra days', style: AppText.meta),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink4),
            ],
          ),
        ),
        if (!Modules.compOff) ...[
          const SizedBox(height: AppSpace.x12),
          const _CompOffCard(),
        ],

        const SizedBox(height: AppSpace.x20),
        _Heading('My requests'),
        const SizedBox(height: AppSpace.x10),
        if (data.requests.isEmpty)
          const _EmptyRequests()
        else
          for (final request in data.requests) ...[
            _RequestCard(request: request),
            const SizedBox(height: AppSpace.x10),
          ],

        if (data.holidays.isNotEmpty) ...[
          const SizedBox(height: AppSpace.x10),
          _Heading('Upcoming holidays'),
          const SizedBox(height: AppSpace.x10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < data.holidays.take(5).length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.line2),
                  _HolidayRow(holiday: data.holidays[i]),
                ],
              ],
            ),
          ),
        ],
      ],
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
      style: AppText.cardTitle.copyWith(fontSize: 13.5, color: AppColors.ink2),
    ),
  );
}

/// Visible but non-interactive: `CompensatoryLeaveRequest` exists on the
/// server, but there is no REST route for it at all, so there is nothing
/// this card could actually call yet. Shown rather than hidden so the
/// feature is not a surprise once [Modules.compOff] flips on.
class _CompOffCard extends StatelessWidget {
  const _CompOffCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.x16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comp-off',
                  style: AppText.cardTitle.copyWith(
                    fontSize: 14,
                    color: AppColors.ink3,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Encash extra hours worked', style: AppText.meta),
              ],
            ),
          ),
          Text('Coming soon', style: AppText.meta),
        ],
      ),
    );
  }
}

/// Colour per leave type, cycled in the handoff's order.
Color leaveTypeColor(int index) => const [
  AppColors.brandStrong,
  AppColors.info,
  AppColors.success,
  AppColors.warning,
][index % 4];

class _BalanceGrid extends StatelessWidget {
  const _BalanceGrid({required this.balances});

  final List<LeaveBalance> balances;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across; two once text is large enough that three cannot hold
        // a label.
        final scaled = MediaQuery.textScalerOf(context).scale(1);
        final columns = scaled > 1.4 ? 2 : 3;
        const gap = AppSpace.x10;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < balances.length; i++)
              SizedBox(
                width: width,
                child: _BalanceCard(
                  balance: balances[i],
                  color: leaveTypeColor(i),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.color});

  final LeaveBalance balance;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = balance.totalDays;
    final carried = balance.carryforwardDays;
    // The ring is the days you hold, split fresh / carried. It is not
    // "used of allocated": the server does not send the annual allocation,
    // and a ring pretending to know it would be a made-up number.
    final carriedShare = total <= 0 ? 0.0 : (carried / total).clamp(0.0, 1.0);

    return Semantics(
      // Its own node, so each balance is a separate screen-reader stop
      // rather than being merged with its neighbours.
      container: true,
      label:
          '${balance.type.name}: ${formatDays(total)} '
          '${total == 1 ? 'day' : 'days'} available'
          '${carried > 0 ? ', ${formatDays(carried)} carried forward' : ''}',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(
                painter: _DonutPainter(
                  color: total <= 0 ? AppColors.line : color,
                  carriedShare: carriedShare,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        formatDays(total),
                        style: AppText.mono.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.x10),
            Text(
              _shortName(balance.type.name),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.cardTitle.copyWith(fontSize: 13),
            ),
            Text(
              carried > 0 ? '+${formatDays(carried)} carried' : 'days left',
              textAlign: TextAlign.center,
              style: AppText.mono.copyWith(fontSize: 10, color: AppColors.ink4),
            ),
          ],
        ),
      ),
    );
  }

  /// "Casual Leave" -> "Casual": the card already says it is leave.
  static String _shortName(String name) {
    final trimmed = name.replaceAll(
      RegExp(r'\s+leave$', caseSensitive: false),
      '',
    );
    return trimmed.isEmpty ? name : trimmed;
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.color, required this.carriedShare});

  final Color color;
  final double carriedShare;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final arc = (Offset.zero & size).deflate(stroke / 2);
    final fresh = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color;
    const start = -math.pi / 2;
    final freshSweep = math.pi * 2 * (1 - carriedShare);
    canvas.drawArc(arc, start, freshSweep, false, fresh);
    if (carriedShare > 0) {
      canvas.drawArc(
        arc,
        start + freshSweep,
        math.pi * 2 * carriedShare,
        false,
        fresh..color = color.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.color != color || old.carriedShare != carriedShare;
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final LeaveRequestSummary request;

  @override
  Widget build(BuildContext context) {
    final range =
        request.endDate == null ||
            request.endDate!.isAtSameMomentAs(request.startDate)
        ? DateFormat('d MMM').format(request.startDate)
        : '${DateFormat('d MMM').format(request.startDate)} – '
              '${DateFormat('d MMM').format(request.endDate!)}';

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.x16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.type?.name ?? 'Leave',
                  style: AppText.cardTitle.copyWith(fontSize: 14.5),
                ),
                const SizedBox(height: AppSpace.x4),
                Text(
                  '$range · ${formatDays(request.requestedDays)} '
                  '${request.requestedDays == 1 ? 'day' : 'days'}',
                  style: AppText.body.copyWith(
                    fontSize: 12.5,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.x8),
          StatusChip(request.status.label, tone: _tone(request.status)),
        ],
      ),
    );
  }

  StatusTone _tone(LeaveStatus status) => switch (status) {
    LeaveStatus.approved => StatusTone.success,
    LeaveStatus.rejected => StatusTone.danger,
    LeaveStatus.cancelled => StatusTone.neutral,
    LeaveStatus.requested => StatusTone.warning,
  };
}

class _HolidayRow extends StatelessWidget {
  const _HolidayRow({required this.holiday});

  final Holiday holiday;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              holiday.name,
              style: AppText.cardTitle.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            DateFormat('d MMM').format(holiday.startDate),
            style: AppText.mono.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// `2.0` reads as `2`, `8.5` stays `8.5`. Leave is counted in half-days, so a
/// trailing `.0` is noise on every whole number.
String formatDays(double days) {
  if (days == days.roundToDouble()) return days.toStringAsFixed(0);
  return days.toStringAsFixed(1);
}

class _NoBalances extends StatelessWidget {
  const _NoBalances();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('No leave assigned'),
          const SizedBox(height: AppSpace.x8),
          Text(
            'No leave types have been assigned to you yet. Your HR team sets '
            'these up.',
            style: AppText.body,
          ),
        ],
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Text('You have not requested any leave.', style: AppText.body),
    );
  }
}

class _LeaveSkeleton extends StatelessWidget {
  const _LeaveSkeleton();

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
        AppCard.skeleton(height: 136),
        SizedBox(height: AppSpace.x16),
        AppCard.skeleton(height: 56),
        SizedBox(height: AppSpace.x20),
        AppCard.skeleton(height: 160),
      ],
    );
  }
}
