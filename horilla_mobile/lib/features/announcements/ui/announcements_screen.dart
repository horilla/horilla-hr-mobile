import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../../home/data/home_api.dart';
import '../data/announcement_models.dart';
import '../data/announcements_api.dart';

final _date = DateFormat('d MMM yyyy');

/// Opens one announcement, then refreshes what its read state feeds.
Future<void> openAnnouncement(
  BuildContext context,
  WidgetRef ref,
  int id,
) async {
  await context.push('/home/announcements/$id');
  ref.invalidate(announcementsProvider);
}

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(title: 'Announcements', onBack: () => context.pop()),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandStrong,
              onRefresh: () async => ref.refresh(announcementsProvider.future),
              child: _body(ref, feed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(WidgetRef ref, AsyncValue<List<Announcement>> feed) {
    final data = feed.value;
    if (data != null) return _Feed(announcements: data);

    final error = feed.error;
    if (error != null) {
      return ErrorStateCard(
        failure: error is ApiFailure ? error : const ApiUnknown(),
        onRetry: () => ref.invalidate(announcementsProvider),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpace.screen),
      children: const [
        AppCard.skeleton(height: 88),
        SizedBox(height: AppSpace.x10),
        AppCard.skeleton(height: 88),
      ],
    );
  }
}

class _Feed extends ConsumerWidget {
  const _Feed({required this.announcements});

  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (announcements.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EyebrowLabel('Nothing posted'),
                const SizedBox(height: AppSpace.x8),
                Text(
                  'Company announcements addressed to you will appear here.',
                  style: AppText.body,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x16,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      itemCount: announcements.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.x10),
      itemBuilder: (context, i) {
        final a = announcements[i];
        final unread = !a.hasViewed;
        final preview = a.preview;
        return Semantics(
          button: true,
          label: unread ? 'Unread: ${a.title}' : a.title,
          excludeSemantics: true,
          child: AppCard(
            borderColor: unread ? AppColors.cardBorder : AppColors.line2,
            shadow: unread,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            onTap: () => openAnnouncement(context, ref, a.id),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: unread ? AppColors.brandStrong : AppColors.readDot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (a.createdAt != null) ...[
                        Text(
                          _date.format(a.createdAt!.toLocal()),
                          style: AppText.mono.copyWith(
                            fontSize: 11,
                            color: AppColors.ink4,
                          ),
                        ),
                        const SizedBox(height: AppSpace.x4),
                      ],
                      Text(
                        a.title,
                        style: AppText.cardTitle.copyWith(
                          fontSize: 14.5,
                          color: unread ? AppColors.ink : AppColors.ink2,
                        ),
                      ),
                      if (preview != null) ...[
                        const SizedBox(height: AppSpace.x4),
                        Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            fontSize: 13,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({super.key, required this.announcementId});

  final int announcementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcement = ref.watch(announcementProvider(announcementId));
    // Opening it marked it read server-side; home's card follows on refresh.
    ref.listen(announcementProvider(announcementId), (_, next) {
      if (next.hasValue) ref.invalidate(homeProvider);
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(title: 'Announcement', onBack: () => context.pop()),
          Expanded(child: _body(ref, announcement)),
        ],
      ),
    );
  }

  Widget _body(WidgetRef ref, AsyncValue<Announcement> announcement) {
    final data = announcement.value;
    if (data != null) return _Detail(announcement: data);

    final error = announcement.error;
    if (error != null) {
      return ErrorStateCard(
        failure: error is ApiFailure ? error : const ApiUnknown(),
        onRetry: () => ref.invalidate(announcementProvider(announcementId)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpace.screen),
      children: const [AppCard.skeleton(height: 220)],
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = announcement;
    final host = ref.watch(sessionProvider)?.host ?? '';
    final meta = [
      if (a.createdAt != null) _date.format(a.createdAt!.toLocal()),
      ?a.author,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.x18,
        AppSpace.screen,
        AppSpace.scrollBottom,
      ),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.x20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (meta.isNotEmpty) ...[
                Text(
                  meta,
                  style: AppText.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.ink4,
                  ),
                ),
                const SizedBox(height: AppSpace.x8),
              ],
              Text(a.title, style: AppText.cardTitle.copyWith(fontSize: 19)),
              for (final block in a.content) _Block(block),
              if (a.expireDate != null) ...[
                const SizedBox(height: AppSpace.x16),
                Text(
                  'Visible until ${_date.format(a.expireDate!)}',
                  style: AppText.meta.copyWith(color: AppColors.ink4),
                ),
              ],
            ],
          ),
        ),
        if (a.attachments.isNotEmpty) ...[
          const SizedBox(height: AppSpace.x20),
          const EyebrowLabel('Attachments'),
          const SizedBox(height: AppSpace.x10),
          for (final file in a.attachments) ...[
            file.isImage
                ? _ImageAttachment(url: file.resolve(host), name: file.name)
                : _FileAttachment(name: file.name),
            const SizedBox(height: AppSpace.x10),
          ],
        ],
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.block);

  final ContentBlock block;

  @override
  Widget build(BuildContext context) {
    final body = AppText.body.copyWith(fontSize: 14.5, height: 1.5);
    return Padding(
      padding: EdgeInsets.only(
        top: block.type == BlockType.heading ? AppSpace.x16 : AppSpace.x8,
      ),
      child: switch (block.type) {
        BlockType.heading => Text(
          block.text,
          style: AppText.cardTitle.copyWith(fontSize: 15.5),
        ),
        BlockType.paragraph => Text(block.text, style: body),
        BlockType.bullet => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: body),
            Expanded(child: Text(block.text, style: body)),
          ],
        ),
      },
    );
  }
}

class _ImageAttachment extends ConsumerWidget {
  const _ImageAttachment({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(attachmentBytesProvider(url));
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.tile),
      child: switch (bytes) {
        AsyncData(:final value) => Image.memory(
          value,
          semanticLabel: name,
          fit: BoxFit.cover,
          // A login redirect answers 200 with HTML, which won't decode.
          errorBuilder: (_, _, _) => _FileAttachment(name: name),
        ),
        AsyncError() => _FileAttachment(name: name),
        _ => const AppCard.skeleton(height: 160),
      },
    );
  }
}

// ponytail: names only. Opening a PDF needs url_launcher or a viewer; add it
// when someone asks to open attachments in the app.
class _FileAttachment extends StatelessWidget {
  const _FileAttachment({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      shadow: false,
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: AppColors.ink3,
          ),
          const SizedBox(width: AppSpace.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Open Horilla on the web to download',
                  style: AppText.meta.copyWith(color: AppColors.ink4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
