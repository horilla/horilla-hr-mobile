import 'package:flutter/material.dart';

import '../../core/api/api_failure.dart';
import '../../core/theme/tokens.dart';
import 'app_card.dart';
import 'app_primitives.dart';

/// "It did not load, here is why, tap to try again."
///
/// Extracted once three screens wanted it. Scrollable on purpose: it is
/// handed to a RefreshIndicator, which needs a scrollable child, so
/// pull-to-refresh keeps working on a screen that has nothing to show.
class ErrorStateCard extends StatelessWidget {
  const ErrorStateCard({
    super.key,
    required this.failure,
    required this.onRetry,
  });

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
