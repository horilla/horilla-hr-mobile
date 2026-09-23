/// In-app notifications.
///
/// Backed by django-notifications-hq, so the payload is generic: a `verb`
/// describing what happened, and a `data` blob the Horilla side fills with a
/// redirect path and an icon. There is no title/body pair to bind to, which
/// is why the verb does the work here.
library;

class AppNotification {
  const AppNotification({
    required this.id,
    required this.verb,
    required this.unread,
    this.timestamp,
    this.redirect,
  });

  final int id;
  final String verb;
  final bool unread;
  final DateTime? timestamp;

  /// Where tapping it should go, when the server says.
  ///
  /// Server-supplied rather than derived here, so a new notification type
  /// does not need an app release -- the same reasoning as push deep links.
  final String? redirect;

  /// Today / Earlier, the two groups the handoff shows.
  bool isToday(DateTime now) {
    final at = timestamp;
    if (at == null) return false;
    final local = at.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  static AppNotification? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;

    final verb = value['verb'];
    if (verb is! String || verb.isEmpty) return null;

    final timestamp = value['timestamp'];
    final data = value['data'];
    final redirect = data is Map ? data['redirect'] : null;

    return AppNotification(
      id: value['id'] is int ? value['id'] as int : 0,
      verb: verb,
      unread: value['unread'] == true,
      timestamp: timestamp is String ? DateTime.tryParse(timestamp) : null,
      // Horilla stores paths like "/leave/request-view?id=3". Anything that
      // is not a local path is ignored rather than followed: a redirect is a
      // navigation instruction from the server, and one pointing off-app is
      // not something to obey blindly.
      redirect: redirect is String &&
              redirect.startsWith('/') &&
              !redirect.startsWith('//')
          ? redirect
          : null,
    );
  }
}

/// The list, split the way the screen draws it.
class NotificationInbox {
  const NotificationInbox({required this.all, required DateTime now})
      : _now = now;

  final List<AppNotification> all;
  final DateTime _now;

  static NotificationInbox empty(DateTime now) =>
      NotificationInbox(all: const [], now: now);

  List<AppNotification> get today =>
      all.where((n) => n.isToday(_now)).toList();

  List<AppNotification> get earlier =>
      all.where((n) => !n.isToday(_now)).toList();

  int get unreadCount => all.where((n) => n.unread).length;

  bool get isEmpty => all.isEmpty;
}
