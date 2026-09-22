import 'package:flutter/material.dart';

import '../../core/theme/platform_chrome.dart';
import '../../core/theme/tokens.dart';
import 'app_card.dart';
import 'app_primitives.dart';

/// Stands in for a screen that has not been built yet.
///
/// Renders the real app bar and a skeleton card so the shell can be walked and
/// reviewed before the screens exist. Deleted as each screen lands.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.dark = false});

  final String title;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark ? AppColors.ink : AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: PlatformChrome.appBarPadding,
            decoration: BoxDecoration(
              color: dark ? AppColors.ink : AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: dark ? Colors.transparent : AppColors.line,
                ),
              ),
            ),
            child: Text(
              title,
              style: AppText.appBarTitle.copyWith(
                color: dark ? AppColors.surface : AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.x18,
                AppSpace.screen,
                AppSpace.scrollBottom,
              ),
              children: const [
                EyebrowLabel('Not built yet'),
                SizedBox(height: AppSpace.x12),
                AppCard.skeleton(),
                SizedBox(height: AppSpace.x12),
                AppCard.skeleton(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
