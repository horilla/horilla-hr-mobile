import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
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
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: PlatformChrome.appBarPadding,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/time'),
                  child: const SizedBox(
                    width: kMinHitTarget,
                    height: 28,
                    child: Icon(Icons.chevron_left, color: AppColors.ink),
                  ),
                ),
                Text('Leave', style: AppText.appBarTitle),
              ],
            ),
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
      return _LeaveError(
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x18,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        if (data.balances.isEmpty)
          const _NoBalances()
        else
          _BalanceGrid(balances: data.balances),

        const SizedBox(height: AppSpace.x16),
        AppButton(
          label: 'Apply for leave',
          onPressed: () => context.push('/time/leave/apply'),
        ),

        const SizedBox(height: AppSpace.x20),
        const SectionHeader(title: 'My requests'),
        const SizedBox(height: AppSpace.x12),
        if (data.requests.isEmpty)
          const _EmptyRequests()
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < data.requests.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.line2),
                  _RequestRow(request: data.requests[i]),
                ],
              ],
            ),
          ),

        if (data.holidays.isNotEmpty) ...[
          const SizedBox(height: AppSpace.x20),
          const SectionHeader(title: 'Upcoming holidays'),
          const SizedBox(height: AppSpace.x12),
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

class _BalanceGrid extends StatelessWidget {
  const _BalanceGrid({required this.balances});

  final List<LeaveBalance> balances;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: balances.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.x10),
        itemBuilder: (context, index) {
          final balance = balances[index];
          return SizedBox(
            width: 116,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpace.x14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDays(balance.totalDays),
                    style: AppText.statValue,
                  ),
                  Text(
                    balance.type.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final LeaveRequestSummary request;

  @override
  Widget build(BuildContext context) {
    final range = request.endDate == null ||
            request.endDate!.isAtSameMomentAs(request.startDate)
        ? DateFormat('d MMM').format(request.startDate)
        : '${DateFormat('d MMM').format(request.startDate)} – '
            '${DateFormat('d MMM').format(request.endDate!)}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: AppSpace.x12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.type?.name ?? 'Leave',
                  style: AppText.cardTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: AppSpace.x4),
                Text(
                  '$range · ${formatDays(request.requestedDays)} '
                  '${request.requestedDays == 1 ? 'day' : 'days'}',
                  style: AppText.meta,
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: AppSpace.x12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              holiday.name,
              style: AppText.cardTitle.copyWith(fontSize: 14),
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
        AppSpace.x18,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: const [
        AppCard.skeleton(height: 96),
        SizedBox(height: AppSpace.x20),
        AppCard.skeleton(height: 160),
      ],
    );
  }
}

class _LeaveError extends StatelessWidget {
  const _LeaveError({required this.failure, required this.onRetry});

  final ApiFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x18,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        AppCard(
          onTap: onRetry,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EyebrowLabel('Could not load'),
              const SizedBox(height: AppSpace.x8),
              Text(failure.message, style: AppText.body),
              const SizedBox(height: AppSpace.x12),
              Text(
                'Tap to try again',
                style: AppText.meta.copyWith(
                  color: AppColors.brandStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
