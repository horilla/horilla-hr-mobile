import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../data/employee_models.dart';

/// A colleague's public card.
///
/// A sheet rather than a pushed route: it is a glance at one person, not a
/// place you navigate to, and it keeps the directory underneath so the next
/// person is one dismissal away.
///
/// It shows only what the directory payload carries -- name, role, and the
/// ways to contact them. Anything more (date of birth, home address,
/// emergency contacts) is HR-owned and this screen deliberately never asks
/// the server for it.
Future<void> showProfileSheet(BuildContext context, DirectoryEntry person) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.hero)),
    ),
    builder: (context) => _ProfileSheet(person: person),
  );
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({required this.person});

  final DirectoryEntry person;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.x20,
          AppSpace.x8,
          AppSpace.x20,
          AppSpace.x28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(name: person.fullName, size: 56),
                const SizedBox(width: AppSpace.x14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        style: AppText.cardTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (person.jobPosition != null) ...[
                        const SizedBox(height: AppSpace.x4),
                        Text(person.jobPosition!, style: AppText.meta),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (person.email != null) ...[
              const SizedBox(height: AppSpace.x20),
              const EyebrowLabel('Contact'),
              const SizedBox(height: AppSpace.x8),
              Text(person.email!, style: AppText.body),
            ],
          ],
        ),
      ),
    );
  }
}
