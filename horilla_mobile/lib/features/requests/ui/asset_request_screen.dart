import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Screen 13 of the handoff: request company-owned equipment.
///
/// The handoff also shows "Allocated to me" rows above the request form --
/// what is currently assigned, with Return / Report actions. That reads from
/// asset allocations, which have no return/report endpoints yet either; the
/// request half is complete on its own and is what ships this pass.
class AssetRequestScreen extends ConsumerStatefulWidget {
  const AssetRequestScreen({super.key});

  @override
  ConsumerState<AssetRequestScreen> createState() => _AssetRequestScreenState();
}

class _AssetRequestScreenState extends ConsumerState<AssetRequestScreen> {
  final _reason = TextEditingController();
  AssetCategoryOption? _selected;
  bool _busy = false;
  String? _error;
  String? _reasonError;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
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
      setState(() => _error = 'Choose what you need.');
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _reasonError = 'Say what it is for.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref
          .read(requestsApiProvider)
          .submitAssetRequest(
            AssetRequestDraft(
              categoryId: selected.id,
              reason: _reason.text.trim(),
            ),
            session.user.id,
          );
      ref.invalidate(requestInboxProvider);
      ref.read(toastProvider.notifier).show('Asset request sent');
      if (mounted) context.pop(true);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(assetCategoryOptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(title: 'Request an asset', onBack: () => context.pop()),
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

                const EyebrowLabel('Category'),
                const SizedBox(height: AppSpace.x10),
                categories.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Text(
                        'No asset categories are configured.',
                        style: AppText.body,
                      );
                    }
                    return Wrap(
                      spacing: AppSpace.x8,
                      runSpacing: AppSpace.x8,
                      children: [
                        for (final category in list)
                          _CategoryChip(
                            category: category,
                            selected: _selected?.id == category.id,
                            onTap: () => setState(() => _selected = category),
                          ),
                      ],
                    );
                  },
                  error: (error, _) => Text(
                    error is ApiFailure
                        ? error.message
                        : 'Could not load categories.',
                    style: AppText.meta.copyWith(color: AppColors.danger),
                  ),
                  loading: () => const SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SkeletonBar(
                        width: 220,
                        height: 36,
                        radius: AppRadii.chip,
                      ),
                    ),
                  ),
                ),

                if (_selected != null) ...[
                  const SizedBox(height: AppSpace.x10),
                  Text(
                    _selected!.available > 0
                        ? 'In stock · ${_selected!.available} available'
                        : 'None currently in stock — the request still '
                              'reaches IT for the next order.',
                    style: AppText.meta.copyWith(
                      color: _selected!.available > 0
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpace.x18),
                AppCard(
                  borderColor: _reasonError == null
                      ? AppColors.cardBorder
                      : AppColors.danger,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel('Justification'),
                      TextField(
                        controller: _reason,
                        minLines: 2,
                        maxLines: 5,
                        style: AppText.body.copyWith(fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 8),
                          hintText: 'What is it for?',
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
                  label: _busy ? 'Sending…' : 'Send request',
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final AssetCategoryOption category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${category.name}, ${category.available} available',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.x14),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTint : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(
              color: selected ? AppColors.brandTintBorder : AppColors.line,
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              category.name,
              style: AppText.meta.copyWith(
                color: selected ? AppColors.brandTintInk : AppColors.ink2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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
