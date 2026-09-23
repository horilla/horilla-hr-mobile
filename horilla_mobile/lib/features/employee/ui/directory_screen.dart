import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../../../shared/widgets/pressable.dart';
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
          const AppTopBar(title: 'Directory'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.screen,
              AppSpace.x6,
              AppSpace.screen,
              AppSpace.x4,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.x16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.field),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: AppColors.ink4),
                  const SizedBox(width: AppSpace.x10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: _onChanged,
                      style: AppText.body.copyWith(fontSize: 14),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search by name',
                        contentPadding: EdgeInsets.symmetric(
                          vertical: AppSpace.x16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EyebrowLabel('No matches'),
                const SizedBox(height: AppSpace.x6),
                Text(
                  'No one matched that search. Check the spelling, or try '
                  'a first or last name on its own.',
                  style: AppText.body,
                ),
              ],
            ),
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
        EyebrowLabel(
          '${people.length} ${people.length == 1 ? 'person' : 'people'}',
        ),
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
    return Semantics(
      button: true,
      label:
          '${person.fullName}'
          '${person.jobPosition == null ? '' : ', ${person.jobPosition}'}',
      excludeSemantics: true,
      child: Pressable(
        scale: 0.99,
        onTap: () => showProfileSheet(context, person),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x16,
            vertical: 13,
          ),
          child: Row(
            children: [
              AppAvatar.toned(name: person.fullName, size: 38),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.fullName,
                      style: AppText.cardTitle.copyWith(fontSize: 14.5),
                    ),
                    if (person.jobPosition != null) ...[
                      const SizedBox(height: 2),
                      Text(person.jobPosition!, style: AppText.meta),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.ink4),
            ],
          ),
        ),
      ),
    );
  }
}
