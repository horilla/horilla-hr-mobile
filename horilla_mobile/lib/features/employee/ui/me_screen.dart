import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/auth/session.dart';
import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../data/profile_api.dart';

final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final version = ref.watch(_appVersionProvider).value;
    final canEdit = ref.watch(canEditProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: PlatformChrome.appBarPadding,
            child: Text('Me', style: AppText.appBarTitle),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.x18,
                AppSpace.screen,
                AppSpace.scrollBottom,
              ),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      AppAvatar(
                        name: session?.user.fullName ?? '?',
                        size: 56,
                      ),
                      const SizedBox(width: AppSpace.x14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session?.user.fullName ?? 'Signed out',
                              style: AppText.cardTitle.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: AppSpace.x4),
                            Text(
                              _roleLabel(session?.capabilities.role),
                              style: AppText.meta,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (session != null && session.isCleartext) ...[
                  const SizedBox(height: AppSpace.x12),
                  // Never invisible: an unencrypted connection stays visible
                  // for as long as it is in use, not just at sign-in.
                  AppCard(
                    background: AppColors.warningBg,
                    borderColor: AppColors.warningBorder,
                    padding: const EdgeInsets.all(AppSpace.x12),
                    child: Text(
                      'This connection is not encrypted.',
                      style: AppText.meta.copyWith(
                        color: AppColors.warningInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpace.x20),
                const SectionHeader(title: 'Personal'),
                const SizedBox(height: AppSpace.x12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Row(
                        label: 'Personal information',
                        // Offered only when the server says self-service
                        // editing is on. A form that always fails is worse
                        // than no form.
                        value: canEdit ? null : 'HR-managed',
                        onTap: canEdit
                            ? () => context.push('/me/personal-information')
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.x20),
                const SectionHeader(title: 'Account'),
                const SizedBox(height: AppSpace.x12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Row(
                        label: 'Server',
                        value: session?.host ?? '—',
                      ),
                      const Divider(height: 1, color: AppColors.line2),
                      _Row(
                        label: 'Sign out',
                        valueColor: AppColors.danger,
                        onTap: () =>
                            ref.read(sessionProvider.notifier).signOut(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.x20),
                // Honest about what this build does and does not do, rather
                // than leaving someone hunting for a tab that is not there.
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel('In this version'),
                      const SizedBox(height: AppSpace.x8),
                      Text(
                        'Attendance, leave and your team directory. '
                        'Payslips, requests and helpdesk are in the Horilla '
                        'web app for now.',
                        style: AppText.body,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.x20),
                Center(
                  child: Text(
                    version == null ? 'Horilla HR' : 'Horilla HR · $version',
                    style: AppText.mono.copyWith(
                      fontSize: 11,
                      color: AppColors.ink4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String? role) => switch (role) {
        'hrexec' => 'HR executive',
        'manager' => 'Manager',
        _ => 'Employee',
      };
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    this.value,
    this.valueColor,
    this.onTap,
  });

  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: kMinHitTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16,
          vertical: AppSpace.x14,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppText.cardTitle.copyWith(
                  fontSize: 14,
                  color: valueColor ?? AppColors.ink,
                ),
              ),
            ),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta,
                ),
              ),
            if (onTap != null && value == null)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.ink4,
              ),
          ],
        ),
      ),
    );
  }
}
