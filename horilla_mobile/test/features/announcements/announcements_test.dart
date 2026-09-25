/// Announcements: parsing both server generations, and the detail fallback.
///
/// Servers before the detail route only have the list, which already carries
/// the body. Opening an announcement there must still work -- from the list's
/// copy -- rather than failing on the missing route.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/core/api/api_failure.dart';
import 'package:horilla_mobile/core/api/error_interceptor.dart';
import 'package:horilla_mobile/features/announcements/data/announcement_models.dart';
import 'package:horilla_mobile/features/announcements/data/announcements_api.dart';

class _Stub implements HttpClientAdapter {
  _Stub(this.routes);

  final Map<String, (int, Object?)> routes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) = routes[options.path] ?? (404, {'detail': 'x'});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AnnouncementsApi api(Map<String, (int, Object?)> routes) {
  final dio = Dio(BaseOptions(baseUrl: 'https://hr.example.test/api/v1'))
    ..httpClientAdapter = _Stub(routes)
    ..interceptors.add(ErrorInterceptor());
  return AnnouncementsApi(dio);
}

// Trimmed from hr.demo.horilla.com's current list response.
final listItem = {
  'id': 7,
  'title': 'Office closed Friday',
  'content': [
    {'type': 'heading', 'text': 'Maintenance'},
    {'type': 'paragraph', 'text': 'The building is closed for repairs.'},
  ],
  'created_at': '2026-09-20T10:00:00+05:30',
  'expire_date': '2026-10-20',
  'has_viewed': false,
};

final list = (
  200,
  {
    'count': 1,
    'next': null,
    'results': [listItem],
  },
);

void main() {
  group('parsing', () {
    test('a list item: preview skips the heading, unread is kept', () {
      final a = Announcement.fromJson(listItem)!;
      expect(a.preview, 'The building is closed for repairs.');
      expect(a.hasViewed, isFalse);
      expect(a.attachments, isEmpty);
    });

    test('detail extras: bullets, attachments, author', () {
      final a = Announcement.fromJson({
        ...listItem,
        'content': [
          {'type': 'bullet', 'text': 'Bring your badge'},
          {'type': 'mystery', 'text': 'Still shown'},
          {'type': 'paragraph', 'text': '  '},
        ],
        'attachments': [
          {
            'name': 'map.png',
            'url': '/media/base/announcement/map.png',
            'is_image': true,
          },
          {'url': 'https://cdn.example/rota.pdf', 'is_image': false},
        ],
        'author': 'Jane Admin',
      })!;
      expect(a.content.map((b) => b.type), [
        BlockType.bullet,
        BlockType.paragraph,
      ]);
      expect(
        a.attachments.first.resolve('https://hr.example.test'),
        'https://hr.example.test/media/base/announcement/map.png',
      );
      expect(a.attachments.last.name, 'rota.pdf');
      expect(
        a.attachments.last.resolve('https://hr.example.test'),
        'https://cdn.example/rota.pdf',
      );
      expect(a.author, 'Jane Admin');
    });

    test('no has_viewed at all does not paint it unread', () {
      expect(Announcement.fromJson({'id': 1, 'title': 'x'})!.hasViewed, isTrue);
    });
  });

  group('detail', () {
    test('uses the detail route when the server has it', () async {
      final a = await api({
        '/base/announcement-view/7': (
          200,
          {...listItem, 'has_viewed': true, 'author': 'Jane Admin'},
        ),
      }).fetchOne(7);
      expect(a.author, 'Jane Admin');
    });

    test('an older server without the route falls back to the list', () async {
      final a = await api({'/base/announcement-view': list}).fetchOne(7);
      expect(a.title, 'Office closed Friday');
      expect(a.content, hasLength(2));
    });

    test('not in the list either is not found', () async {
      expect(
        () => api({'/base/announcement-view': list}).fetchOne(99),
        throwsA(isA<ApiNotFound>()),
      );
    });

    test('other failures are not masked by the fallback', () async {
      expect(
        () => api({
          '/base/announcement-view/7': (403, {'detail': 'no'}),
          '/base/announcement-view': list,
        }).fetchOne(7),
        throwsA(isA<ApiForbidden>()),
      );
    });
  });
}
