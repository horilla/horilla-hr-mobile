import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import 'home_models.dart';

class HomeApi {
  HomeApi(this._dio);

  final Dio _dio;

  Future<HomeData> fetch() async {
    try {
      final response = await _dio.get<dynamic>('/mobile/home/');
      final body = response.data;
      if (body is! Map<String, dynamic>) throw const ApiIncompatibleServer();
      return HomeData.fromJson(body);
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }
}

final homeApiProvider = Provider<HomeApi>(
  (ref) => HomeApi(ref.watch(apiClientProvider).dio),
);

/// The home screen's data.
///
/// Riverpod's cache is the whole caching story here: `valueOrNull` survives a
/// refresh, so pull-to-refresh re-fetches without blanking the screen, and
/// skeletons show only on a genuine first load.
final homeProvider = FutureProvider<HomeData>((ref) async {
  return ref.watch(homeApiProvider).fetch();
});
