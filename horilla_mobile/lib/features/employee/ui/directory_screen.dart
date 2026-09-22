import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../data/employee_api.dart';
import '../data/employee_models.dart';
import 'profile_sheet.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Search hits the server, so it waits for a pause in typing rather than
  /// firing a request per keystroke.
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(directorySearchProvider.notifier).update(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(directoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: PlatformChrome.appBarPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Team', style: AppText.appBarTitle),
                const SizedBox(height: AppSpace.x12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.x12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.ink4,
                      ),
                      const SizedBox(width: AppSpace.x8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: _onChanged,
                          style: AppText.body,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Search people',
                            contentPadding: EdgeInsets.symmetric(
                              vertical: AppSpace.x12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandStrong,
              onRefresh: () async => ref.refresh(directoryProvider.future),
              child: _body(directory),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AsyncValue<List<DirectoryEntry>> directory) {
    final people = directory.value;
    if (people != null) return _DirectoryList(people: people);

    final error = directory.error;
    if (error != null) {
      return ErrorStateCard(
        failure: error is ApiFailure ? error : const ApiUnknown(),
        onRetry: () => ref.invalidate(directoryProvider),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpace.screen),
      children: const [
        AppCard.skeleton(height: 72),
        SizedBox(height: AppSpace.x10),
        AppCard.skeleton(height: 72),
        SizedBox(height: AppSpace.x10),
        AppCard.skeleton(height: 72),
      ],
    );
  }
}

class _DirectoryList extends StatelessWidget {
  const _DirectoryList({required this.people});

  final List<DirectoryEntry> people;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          AppCard(
            child: Text('No one matched that search.', style: AppText.body),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x16,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        EyebrowLabel('${people.length} ${people.length == 1 ? 'person' : 'people'}'),
        const SizedBox(height: AppSpace.x12),
        // A directory of one usually means the server is scoping this person
        // to themselves, not that they work alone -- worth saying so rather
        // than looking broken.
        if (people.length == 1) ...[
          AppCard(
            background: AppColors.infoBg,
            borderColor: AppColors.infoBorder,
            padding: const EdgeInsets.all(AppSpace.x12),
            child: Text(
              'Your administrator decides who appears here. Ask them if you '
              'expect to see colleagues.',
              style: AppText.meta.copyWith(color: AppColors.infoInk),
            ),
          ),
          const SizedBox(height: AppSpace.x12),
        ],
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < people.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.line2),
                _PersonRow(person: people[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person});

  final DirectoryEntry person;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showProfileSheet(context, person),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x16,
          vertical: AppSpace.x12,
        ),
        child: Row(
          children: [
            AppAvatar(name: person.fullName, size: 38),
            const SizedBox(width: AppSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    style: AppText.cardTitle.copyWith(fontSize: 14),
                  ),
                  if (person.jobPosition != null) ...[
                    const SizedBox(height: AppSpace.x4),
                    Text(person.jobPosition!, style: AppText.meta),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.ink4),
          ],
        ),
      ),
    );
  }
}
