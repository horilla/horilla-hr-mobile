/// Enrolling a reference photo.
///
/// This is the *only* server-side storage the facedetection app has: one
/// image per employee (`EmployeeFaceDetection`, a `OneToOneField`), upserted
/// by this same endpoint. There is no per-punch photo storage anywhere in
/// the backend -- `ClockInAPIView`/`ClockOutAPIView` accept no image field at
/// all -- so the punch-time step is a presence check only, and never calls
/// this endpoint again after the first enrolment.
///
/// Routed outside /api/v1/ entirely: `facedetection/apps.py` mounts its own
/// urls.py directly onto the root urlconf as `api/facedetection/`, not
/// through `horilla_api.urls`. The app's Dio instance has its base URL
/// pinned to `<host>/api/v1`, so these two calls pass an absolute URL to
/// deliberately bypass it -- Dio uses a path verbatim once it has a scheme,
/// ignoring baseUrl, while still going through the same auth/retry/error
/// interceptors since it's the same Dio instance.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';

class FacedetectionApi {
  FacedetectionApi(this._dio);

  final Dio _dio;

  Future<void> uploadReference(String host, Uint8List jpegBytes) async {
    try {
      await _dio.post<dynamic>(
        '$host/api/facedetection/setup/',
        data: FormData.fromMap({
          'image': MultipartFile.fromBytes(jpegBytes, filename: 'face.jpg'),
        }),
      );
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }
  }
}

final facedetectionApiProvider = Provider<FacedetectionApi>(
  (ref) => FacedetectionApi(ref.watch(apiClientProvider).dio),
);
