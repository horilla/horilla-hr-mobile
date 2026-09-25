import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/toast.dart';
import '../data/employee_models.dart';

/// A colleague's public card, in v2's centred layout.
///
/// A sheet rather than the handoff's full screen: it shows only what the
/// directory payload carries -- name, role, email -- and a full screen of
/// three fields is mostly empty. The handoff's reporting line, location and
/// shift come from the work-information record, which also carries salary;
/// this screen deliberately never asks the server for it.
///
/// "Copy email" rather than Call / Email / Chat: the payload has no phone
/// number, the app has no chat, and opening a mail client would need a new
/// dependency for one button.
Future<void> showProfileSheet(BuildContext context, DirectoryEntry person) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.hero)),
    ),
    builder: (context) => _ProfileSheet(person: person),
  );
}

class _ProfileSheet extends ConsumerWidget {
  const _ProfileSheet({required this.person});

  final DirectoryEntry person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.x20,
          0,
          AppSpace.x20,
          AppSpace.x28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar.toned(name: person.fullName, size: 66),
            const SizedBox(height: AppSpace.x14),
            Text(
              person.fullName,
              textAlign: TextAlign.center,
              style: AppText.appBarTitle.copyWith(fontSize: 18),
            ),
            if (person.jobPosition != null) ...[
              const SizedBox(height: AppSpace.x4),
              Text(
                person.jobPosition!,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.ink3),
              ),
            ],
            if (person.email != null) ...[
              const SizedBox(height: AppSpace.x16),
              SelectableText(
                person.email!,
                textAlign: TextAlign.center,
                style: AppText.mono.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: AppSpace.x16),
              AppButton(
                label: 'Copy email',
                tone: AppButtonTone.quiet,
                icon: Icons.copy_outlined,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: person.email!));
                  ref.read(toastProvider.notifier).show('Email copied');
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
