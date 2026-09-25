/// Notification parsing and grouping.
///
/// The redirect is the part worth care: it is a navigation instruction
/// arriving from the server, and obeying one blindly is how an app ends up
/// following a link somewhere it should not.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/notifications/data/notification_models.dart';

void main() {
  group('parsing', () {
    test('a notification needs a verb to say anything', () {
      // The payload is generic -- there is no title/body pair, so the verb is
      // the whole message. Without it there is nothing to show.
      expect(AppNotification.fromJson({'id': 1, 'unread': true}), isNull);
      expect(AppNotification.fromJson({'id': 1, 'verb': ''}), isNull);
      expect(AppNotification.fromJson('nonsense'), isNull);
    });

    test('the usual fields come through', () {
      final notification = AppNotification.fromJson({
        'id': 4,
        'verb': 'Your leave request was approved',
        'unread': true,
        'timestamp': '2026-09-23T09:15:00Z',
      })!;

      expect(notification.id, 4);
      expect(notification.verb, 'Your leave request was approved');
      expect(notification.unread, isTrue);
      expect(notification.timestamp, isNotNull);
    });

    test('a missing timestamp is tolerated', () {
      final notification = AppNotification.fromJson({
        'id': 4,
        'verb': 'Something happened',
      })!;
      expect(notification.timestamp, isNull);
      expect(notification.isToday(DateTime.now()), isFalse);
    });
  });

  group('the redirect is treated as untrusted input', () {
    AppNotification parse(Object? redirect) => AppNotification.fromJson({
      'id': 1,
      'verb': 'x',
      'data': {'redirect': redirect},
    })!;

    test('a local path is kept', () {
      expect(
        parse('/leave/request-view?id=3').redirect,
        '/leave/request-view?id=3',
      );
    });

    test('an absolute URL is refused', () {
      // A notification must not be able to send someone off-app.
      expect(parse('https://example.com/phish').redirect, isNull);
      expect(parse('http://example.com').redirect, isNull);
    });

    test('a protocol-relative URL is refused', () {
      // "//evil.com" is a URL, not a path, and is the easy one to miss.
      expect(parse('//evil.com/path').redirect, isNull);
    });

    test('a non-string or absent redirect is simply absent', () {
      expect(parse(42).redirect, isNull);
      expect(
        AppNotification.fromJson({'id': 1, 'verb': 'x'})!.redirect,
        isNull,
      );
      expect(
        AppNotification.fromJson({
          'id': 1,
          'verb': 'x',
          'data': 'no',
        })!.redirect,
        isNull,
      );
    });
  });

  group('grouping', () {
    final now = DateTime(2026, 9, 23, 14, 0);

    AppNotification at(DateTime when, {bool unread = false}) => AppNotification(
      id: when.millisecondsSinceEpoch ~/ 1000,
      verb: 'x',
      unread: unread,
      timestamp: when,
    );

    test('today and earlier are split by calendar day, not by 24 hours', () {
      // 00:30 today is "today"; 23:30 yesterday is not, even though it is
      // nearer in time.
      final inbox = NotificationInbox(
        now: now,
        all: [
          at(DateTime(2026, 9, 23, 0, 30)),
          at(DateTime(2026, 9, 22, 23, 30)),
        ],
      );

      expect(inbox.today.length, 1);
      expect(inbox.earlier.length, 1);
    });

    test('undated notifications fall into earlier rather than vanishing', () {
      final inbox = NotificationInbox(
        now: now,
        all: [const AppNotification(id: 1, verb: 'x', unread: false)],
      );

      expect(inbox.today, isEmpty);
      expect(inbox.earlier.length, 1);
    });

    test('the unread count counts only unread', () {
      final inbox = NotificationInbox(
        now: now,
        all: [at(now, unread: true), at(now, unread: true), at(now)],
      );

      expect(inbox.unreadCount, 2);
      expect(inbox.isEmpty, isFalse);
    });

    test('an empty inbox says so', () {
      expect(NotificationInbox.empty(now).isEmpty, isTrue);
      expect(NotificationInbox.empty(now).unreadCount, 0);
    });
  });
}
