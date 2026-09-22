import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
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
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: PlatformChrome.appBarPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text('Requests', style: AppText.appBarTitle),
                ),
                GestureDetector(
                  onTap: () => context.push('/requests/payslips'),
                  child: Text(
                    'Payslips',
                    style: AppText.meta.copyWith(
                      color: AppColors.brandStrong,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandStrong,
              onRefresh: () async => ref.refresh(requestInboxProvider.future),
              child: _body(inbox.value ?? RequestInbox.empty,
                  loading: inbox.value == null),
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
