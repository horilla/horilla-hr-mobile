import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import '../../home/data/home_api.dart';
import 'notification_models.dart';

class NotificationsApi {
  NotificationsApi(this._dio);

  final Dio _dio;

  Future<List<AppNotification>> fetchAll() async {
    try {
      // Note the doubled segment: the route really is
      // /notifications/notifications/list/<type>.
      final response = await _dio.get<dynamic>(
        '/notifications/notifications/list/all',
        queryParameters: {'page_size': 50},
      );

      final body = response.data;
      final raw = switch (body) {
        final Map<String, dynamic> map => map['results'],
        final List list => list,
        _ => null,
      };
      if (raw is! List) return const [];

      return raw
          .map(AppNotification.fromJson)
          .whereType<AppNotification>()
          .toList()
        ..sort((a, b) {
          final at = a.timestamp;
          final bt = b.timestamp;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at);
        });
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.post<dynamic>('/notifications/notifications/$id/');
    } on DioException {
      // Deliberately swallowed. Marking one as read is a side effect of
      // opening it; failing that must not stop the navigation or raise an
      // error over something the person did not ask for. The unread badge
      // corrects itself on the next fetch.
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post<dynamic>('/notifications/notifications/bulk-read/');
    } on DioException catch (e) {
      // This one *was* asked for, so it reports.
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }
}

final notificationsApiProvider = Provider<NotificationsApi>(
  (ref) => NotificationsApi(ref.watch(apiClientProvider).dio),
);

final notificationInboxProvider =
    FutureProvider<NotificationInbox>((ref) async {
  final all = await ref.watch(notificationsApiProvider).fetchAll();
  return NotificationInbox(all: all, now: DateTime.now());
});

/// Marks everything read, then refreshes both this screen and home's badge.
Future<void> markAllNotificationsRead(WidgetRef ref) async {
  await ref.read(notificationsApiProvider).markAllRead();
  ref.invalidate(notificationInboxProvider);
  ref.invalidate(homeProvider);
}
