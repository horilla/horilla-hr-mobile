import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/theme/platform_chrome.dart';
import '../../../core/theme/tokens.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_primitives.dart';
import '../../../shared/widgets/error_state_card.dart';
import '../data/notification_models.dart';
import '../data/notifications_api.dart';

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
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: PlatformChrome.appBarPadding,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const SizedBox(
                    width: kMinHitTarget,
                    height: 28,
                    child: Icon(Icons.chevron_left, color: AppColors.ink),
                  ),
                ),
                Expanded(
                  child: Text('Notifications', style: AppText.appBarTitle),
                ),
                if (unread > 0)
                  GestureDetector(
                    onTap: () => markAllNotificationsRead(ref),
                    child: Text(
                      'Mark all read',
                      style: AppText.meta.copyWith(
                        color: AppColors.brandStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
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
          _Group(notifications: inbox.today),
        ],
        if (inbox.earlier.isNotEmpty) ...[
          if (inbox.today.isNotEmpty) const SizedBox(height: AppSpace.x20),
          const EyebrowLabel('Earlier'),
          const SizedBox(height: AppSpace.x10),
          _Group(notifications: inbox.earlier),
        ],
      ],
    );
  }
}

class _Group extends ConsumerWidget {
  const _Group({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < notifications.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line2),
            _NotificationRow(notification: notifications[i]),
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = notification.timestamp;

    return Semantics(
      button: true,
      label: notification.unread
          ? 'Unread: ${notification.verb}'
          : notification.verb,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          if (notification.unread) {
            await ref
                .read(notificationsApiProvider)
                .markRead(notification.id);
            ref.invalidate(notificationInboxProvider);
          }
          // Only local paths survive parsing, so this cannot send someone
          // off-app. Unknown-but-local paths simply do not match a route,
          // which go_router handles rather than crashing.
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x16,
            vertical: AppSpace.x14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: notification.unread
                      ? AppColors.brandStrong
                      : AppColors.readDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpace.x12),
              Expanded(
                child: Text(
                  notification.verb,
                  style: AppText.body.copyWith(
                    color: notification.unread
                        ? AppColors.ink
                        : AppColors.ink3,
                    fontWeight: notification.unread
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              if (time != null) ...[
                const SizedBox(width: AppSpace.x8),
                Text(
                  DateFormat('HH:mm').format(time.toLocal()),
                  style: AppText.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.ink4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
