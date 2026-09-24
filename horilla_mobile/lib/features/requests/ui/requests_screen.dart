import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/request_models.dart';
import '../data/requests_api.dart';

enum _Filter { all, pending, closed }

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(requestInboxProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(
            title: 'Requests',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TopBarAction(
                  label: 'Payslips',
                  onTap: () => context.push('/requests/payslips'),
                ),
                const SizedBox(width: AppSpace.x8),
                _NewRequestButton(onTap: () => _openCreateSheet(context)),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandStrong,
              onRefresh: () async => ref.refresh(requestInboxProvider.future),
              child: _body(
                inbox.value ?? RequestInbox.empty,
                loading: inbox.value == null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(RequestInbox inbox, {required bool loading}) {
    final visible = switch (_filter) {
      _Filter.all => inbox.requests,
      _Filter.pending => inbox.open,
      _Filter.closed => inbox.closed,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x16,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        Row(
          children: [
            _FilterChip(
              label: 'All ${inbox.requests.length}',
              selected: _filter == _Filter.all,
              onTap: () => setState(() => _filter = _Filter.all),
            ),
            const SizedBox(width: AppSpace.x8),
            _FilterChip(
              label: 'Pending ${inbox.open.length}',
              selected: _filter == _Filter.pending,
              onTap: () => setState(() => _filter = _Filter.pending),
            ),
            const SizedBox(width: AppSpace.x8),
            _FilterChip(
              label: 'Closed',
              selected: _filter == _Filter.closed,
              onTap: () => setState(() => _filter = _Filter.closed),
            ),
          ],
        ),

        const SizedBox(height: AppSpace.x20),
        if (loading) ...[
          const AppCard.skeleton(height: 120),
          const SizedBox(height: AppSpace.x12),
          const AppCard.skeleton(height: 120),
        ] else if (visible.isEmpty)
          _EmptyRequests(filter: _filter)
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.line2),
                  _RequestRow(request: visible[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.hero)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.x20,
            0,
            AppSpace.x20,
            AppSpace.x20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What do you need?',
                style: AppText.appBarTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpace.x16),
              _CreateOption(
                icon: Icons.schedule_outlined,
                title: 'Shift / work type',
                subtitle: 'Swap or change your work type',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/requests/shift-request');
                },
              ),
              const SizedBox(height: AppSpace.x10),
              _CreateOption(
                icon: Icons.receipt_long_outlined,
                title: 'Reimbursement',
                subtitle: 'Claim an expense',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/requests/reimburse');
                },
              ),
              const SizedBox(height: AppSpace.x10),
              _CreateOption(
                icon: Icons.devices_outlined,
                title: 'Asset',
                subtitle: 'Laptop, monitor…',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/requests/asset');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewRequestButton extends StatelessWidget {
  const _NewRequestButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New request',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.brandStrong,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.add, size: 18, color: AppColors.surface),
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.x14),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.iconTile),
                ),
                child: Icon(icon, size: 20, color: AppColors.brandStrong),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.meta),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink4),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final WorkRequest request;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (request.date != null) DateFormat('d MMM').format(request.date!),
      if (request.detail != null) request.detail!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x16,
        vertical: AppSpace.x12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EyebrowLabel(request.kind.label),
                const SizedBox(height: AppSpace.x6),
                Text(
                  request.title,
                  style: AppText.cardTitle.copyWith(fontSize: 14),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.x4),
                  Text(meta, style: AppText.meta),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.x8),
          StatusChip(request.state.label, tone: _tone(request.state)),
        ],
      ),
    );
  }

  StatusTone _tone(RequestState state) => switch (state) {
    RequestState.approved => StatusTone.success,
    RequestState.rejected => StatusTone.danger,
    RequestState.cancelled => StatusTone.neutral,
    RequestState.pending => StatusTone.warning,
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
            vertical: AppSpace.x8,
          ),
          decoration: BoxDecoration(
            // The handoff fills the active chip with ink, not brand.
            color: selected ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: AppText.meta.copyWith(
              color: selected ? AppColors.surface : AppColors.ink2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests({required this.filter});

  final _Filter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _Filter.pending => 'Nothing is waiting on anyone.',
      _Filter.closed => 'No closed requests yet.',
      _Filter.all => 'You have not raised any requests.',
    };

    return AppCard(child: Text(message, style: AppText.body));
  }
}
