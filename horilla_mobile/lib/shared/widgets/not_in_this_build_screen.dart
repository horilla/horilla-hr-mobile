import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/platform_chrome.dart';
import '../../core/theme/tokens.dart';
import 'app_card.dart';
import 'app_primitives.dart';

/// Reached only if something deep-links into a module this build has switched
/// off (see `core/scope.dart`).
///
/// It exists so that case is a clear message rather than a blank screen or a
/// crash -- a push notification from a server whose modules do not match the
/// app's is exactly how someone gets here.
class NotInThisBuildScreen extends StatelessWidget {
  const NotInThisBuildScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: PlatformChrome.appBarPaddingOf(context),
            child: Row(
              children: [
                if (context.canPop())
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const SizedBox(
                      width: kMinHitTarget,
                      height: 28,
                      child: Icon(Icons.chevron_left, color: AppColors.ink),
                    ),
                  ),
                Text(title, style: AppText.appBarTitle),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.screen),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EyebrowLabel('Not available yet'),
                  const SizedBox(height: AppSpace.x8),
                  Text(
                    '$title is not part of this version of the app. '
                    'Use the Horilla web app for now.',
                    style: AppText.body,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
