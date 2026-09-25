import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import 'announcement_models.dart';

class AnnouncementsApi {
  AnnouncementsApi(this._dio);

  final Dio _dio;

  /// Unexpired announcements for the caller, newest first -- the server
  /// orders and scopes them.
  // ponytail: one page of 50. Unexpired announcements rarely come close; page
  // through `next` if a company ever does.
  Future<List<Announcement>> fetchAll() async {
    try {
      // No trailing slash: the route really is `announcement-view`.
      final response = await _dio.get<dynamic>(
        '/base/announcement-view',
        queryParameters: {'page_size': 50},
      );
      final body = response.data;
      final raw = switch (body) {
        final Map<String, dynamic> map => map['results'],
        final List list => list,
        _ => null,
      };
      if (raw is! List) return const [];
      return raw.map(Announcement.fromJson).whereType<Announcement>().toList();
    } on DioException catch (e) {
      throw _failure(e);
    }
  }

  /// One announcement with its attachments; opening it marks it read.
  ///
  /// Servers before the detail route answer 404 for it, so fall back to the
  /// list's copy -- the same text, minus attachments. On a current server a
  /// 404 means "not in your audience", and the list won't have it either.
  Future<Announcement> fetchOne(int id) async {
    try {
      final response = await _dio.get<dynamic>('/base/announcement-view/$id');
      final parsed = Announcement.fromJson(response.data);
      if (parsed != null) return parsed;
      throw const ApiUnknown();
    } on DioException catch (e) {
      final failure = _failure(e);
      if (failure is! ApiNotFound) throw failure;
    }
    final all = await fetchAll();
    for (final announcement in all) {
      if (announcement.id == id) return announcement;
    }
    throw const ApiNotFound();
  }

  /// Media is login-protected, so an attachment can't be a bare image URL:
  /// this goes through the same client, token and refresh as everything else.
  Future<Uint8List> fetchBytes(String absoluteUrl) async {
    try {
      final response = await _dio.get<List<int>>(
        absoluteUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw _failure(e);
    }
  }

  ApiFailure _failure(DioException e) {
    final failure = e.error;
    return failure is ApiFailure ? failure : const ApiUnknown();
  }
}

final announcementsApiProvider = Provider<AnnouncementsApi>(
  (ref) => AnnouncementsApi(ref.watch(apiClientProvider).dio),
);

final announcementsProvider = FutureProvider<List<Announcement>>((ref) {
  return ref.watch(announcementsApiProvider).fetchAll();
});

final announcementProvider = FutureProvider.family<Announcement, int>((
  ref,
  id,
) {
  return ref.watch(announcementsApiProvider).fetchOne(id);
});

final attachmentBytesProvider = FutureProvider.family<Uint8List, String>((
  ref,
  url,
) {
  return ref.watch(announcementsApiProvider).fetchBytes(url);
});
