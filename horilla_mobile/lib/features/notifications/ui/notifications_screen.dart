import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../data/notification_models.dart';
import '../data/notifications_api.dart';
import '../../../shared/widgets/app_top_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationInboxProvider);
    final unread = inbox.value?.unreadCount ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppTopBar(
            title: 'Notifications',
            onBack: () => context.pop(),
            trailing: unread > 0
                ? TopBarAction(
                    label: 'Mark read',
                    onTap: () => markAllNotificationsRead(ref),
                  )
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandStrong,
              onRefresh: () async =>
                  ref.refresh(notificationInboxProvider.future),
              child: _body(ref, inbox),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(WidgetRef ref, AsyncValue<NotificationInbox> inbox) {
    final data = inbox.value;
    if (data != null) return _InboxBody(inbox: data);

    final error = inbox.error;
    if (error != null) {
      return ErrorStateCard(
        failure: error is ApiFailure ? error : const ApiUnknown(),
        onRetry: () => ref.invalidate(notificationInboxProvider),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpace.screen),
      children: const [
        AppCard.skeleton(height: 72),
        SizedBox(height: AppSpace.x10),
        AppCard.skeleton(height: 72),
      ],
    );
  }
}

class _InboxBody extends ConsumerWidget {
  const _InboxBody({required this.inbox});

  final NotificationInbox inbox;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (inbox.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpace.screen),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EyebrowLabel('Nothing new'),
                const SizedBox(height: AppSpace.x8),
                Text(
                  "You'll hear about leave decisions, requests and "
                  'announcements here.',
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
        if (inbox.today.isNotEmpty) ...[
          const EyebrowLabel('Today'),
          const SizedBox(height: AppSpace.x10),
          _Group(notifications: inbox.today, today: true),
        ],
        if (inbox.earlier.isNotEmpty) ...[
          if (inbox.today.isNotEmpty) const SizedBox(height: AppSpace.x20),
          const EyebrowLabel('Earlier'),
          const SizedBox(height: AppSpace.x10),
          _Group(notifications: inbox.earlier, today: false),
        ],
      ],
    );
  }
}

/// v2 draws each notification as its own card rather than rows in one.
class _Group extends StatelessWidget {
  const _Group({required this.notifications, required this.today});

  final List<AppNotification> notifications;
  final bool today;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < notifications.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.x10),
          _NotificationRow(notification: notifications[i], today: today),
        ],
      ],
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification, required this.today});

  final AppNotification notification;

  /// Today's show a time; earlier ones a date.
  final bool today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = notification.timestamp?.toLocal();
    final unread = notification.unread;

    return Semantics(
      button: true,
      label: unread ? 'Unread: ${notification.verb}' : notification.verb,
      excludeSemantics: true,
      child: AppCard(
        // Read ones recede: lighter border, no lift.
        borderColor: unread ? AppColors.cardBorder : AppColors.line2,
        shadow: unread,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        onTap: () async {
          if (unread) {
            await ref.read(notificationsApiProvider).markRead(notification.id);
            ref.invalidate(notificationInboxProvider);
          }
          // Only local paths survive parsing, so this cannot send someone
          // off-app. Unknown-but-local paths simply do not match a route,
          // which go_router handles rather than crashing.
        },
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
              child: Text(
                notification.verb,
                style: AppText.body.copyWith(
                  fontSize: 14,
                  height: 1.4,
                  color: unread ? AppColors.ink : AppColors.ink3,
                  fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (time != null) ...[
              const SizedBox(width: AppSpace.x10),
              Text(
                DateFormat(today ? 'HH:mm' : 'd MMM').format(time),
                style: AppText.mono.copyWith(
                  fontSize: 11,
                  color: AppColors.ink4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
