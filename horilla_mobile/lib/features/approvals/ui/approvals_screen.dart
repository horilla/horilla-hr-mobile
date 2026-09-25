import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_filter_chip.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../data/approval_models.dart';
import '../data/approvals_controller.dart';

/// The manager's inbox: one card per request waiting on them.
///
/// Approve / Reject act in one tap -- the card goes, a toast offers Undo,
/// and the decision is only sent when that window closes (see
/// ApprovalsController). Conflict warnings are advisory, never blocking.
class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  ApprovalFilter _filter = ApprovalFilter.all;

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(approvalsProvider);
    final pending = inbox.value?.items.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(
            title: 'Approvals',
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/team'),
            trailing: pending > 0
                ? StatusChip('$pending pending', tone: StatusTone.warning)
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandStrong,
              onRefresh: () async => ref.refresh(approvalsProvider.future),
              child: _body(inbox),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AsyncValue<ApprovalInbox> inbox) {
    final data = inbox.value;
    if (data == null) {
      final error = inbox.error;
      if (error != null) {
        return ErrorStateCard(
          failure: error is ApiFailure ? error : const ApiUnknown(),
          onRetry: () => ref.invalidate(approvalsProvider),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: const [
          AppCard.skeleton(height: 190),
          SizedBox(height: AppSpace.x12),
          AppCard.skeleton(height: 190),
        ],
      );
    }

    final visible = data.visible(_filter);
    final controller = ref.read(approvalsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x6,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        Wrap(
          spacing: AppSpace.x8,
          runSpacing: AppSpace.x8,
          children: [
            for (final filter in ApprovalFilter.values)
              AppFilterChip(
                label: '${filter.label} · ${data.countFor(filter)}',
                selected: _filter == filter,
                onTap: () => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.x16),
        if (visible.isEmpty)
          const _AllCaughtUp()
        else
          for (final item in visible) ...[
            _ApprovalCard(
              key: ValueKey(item.key),
              item: item,
              onApprove: () => controller.decide(item, approve: true),
              onReject: item.canReject
                  ? () => controller.decide(item, approve: false)
                  : null,
            ),
            const SizedBox(height: AppSpace.x12),
          ],
      ],
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final ApprovalItem item;
  final VoidCallback onApprove;

  /// Null where the server has no safe reject for this kind.
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final age = item.submitted == null ? null : _age(item.submitted!);

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar.toned(name: item.name, size: 36),
              const SizedBox(width: AppSpace.x10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.cardTitle.copyWith(fontSize: 14),
                    ),
                    Text(item.kind.label, style: AppText.meta),
                  ],
                ),
              ),
              if (age != null) ...[
                const SizedBox(width: AppSpace.x8),
                Text(
                  age,
                  style: AppText.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.x12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.x12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(AppRadii.iconTile),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ask,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (item.reason != null) ...[
                  const SizedBox(height: AppSpace.x4),
                  Text(item.reason!, style: AppText.meta),
                ],
              ],
            ),
          ),
          if (item.warning != null) ...[
            const SizedBox(height: AppSpace.x10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.x10),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                border: Border.all(color: AppColors.warningBorder),
                borderRadius: BorderRadius.circular(AppRadii.iconTile),
              ),
              child: Text(
                item.warning!,
                style: AppText.meta.copyWith(color: AppColors.warningInk),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.x14),
          if (onReject != null)
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Approve',
                    compact: true,
                    onPressed: onApprove,
                  ),
                ),
                const SizedBox(width: AppSpace.x10),
                Expanded(
                  child: AppButton(
                    label: 'Reject',
                    compact: true,
                    tone: AppButtonTone.outlinedDanger,
                    onPressed: onReject,
                  ),
                ),
              ],
            )
          else ...[
            AppButton(label: 'Approve', compact: true, onPressed: onApprove),
            const SizedBox(height: AppSpace.x6),
            // Said rather than hidden, so a manager looking for Reject knows
            // where it went.
            Text(
              'To reject this one, use the Horilla web app.',
              style: AppText.meta,
            ),
          ],
        ],
      ),
    );
  }

  static String _age(DateTime submitted) {
    final elapsed = DateTime.now().difference(submitted);
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes.clamp(1, 59)}m';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h';
    return '${elapsed.inDays}d';
  }
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.x20),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(AppRadii.iconTile),
            ),
            child: const Icon(Icons.check, color: AppColors.success),
          ),
          const SizedBox(height: AppSpace.x12),
          Text('All caught up', style: AppText.cardTitle),
          const SizedBox(height: AppSpace.x4),
          Text(
            'Nothing is waiting on you in this view.',
            textAlign: TextAlign.center,
            style: AppText.meta,
          ),
        ],
      ),
    );
  }
}
