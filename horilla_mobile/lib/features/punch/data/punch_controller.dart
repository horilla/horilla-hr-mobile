/// Preparing and submitting a punch.
///
/// The whole flow lives here rather than in the widget so it can be tested
/// without hardware: read a position, work out where that is relative to the
/// fence, then submit. Only [LocationService] touches the device, and it is
/// injected.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/auth/session.dart';
import '../../attendance/data/attendance_api.dart';
import '../../home/data/home_api.dart';
import '../../home/data/home_models.dart';
import 'geofence.dart';
import 'location_service.dart';

/// What the confirm screen knows before anyone taps.
@immutable
class PunchPreparation {
  const PunchPreparation({
    required this.isClockingIn,
    this.coordinates,
    this.fence,
    this.locationFailure,
    this.faceImage,
    this.faceCapturedAt,
  });

  final bool isClockingIn;
  final Coordinates? coordinates;
  final FencePosition? fence;
  final LocationFailure? locationFailure;
  final Uint8List? faceImage;
  final DateTime? faceCapturedAt;

  /// Whether the punch button should be live.
  ///
  /// The handoff requires the fence state to be resolved before the button
  /// enables. Where a fence is enforced and the person is outside it, the app
  /// does not offer a button that the server will refuse -- being told "no"
  /// before tapping is better than after.
  bool get canSubmit {
    if (locationFailure != null || coordinates == null) return false;
    final accuracy = coordinates!.accuracy;
    return accuracy != null && accuracy >= 0 && accuracy <= 25;
  }

  String? get blockedReason {
    if (locationFailure != null) return locationFailure!.message;
    if (coordinates == null) return 'Getting your location…';
    final accuracy = coordinates!.accuracy;
    if (accuracy == null || accuracy > 25) {
      return 'GPS accuracy is ${accuracy == null ? 'unavailable' : '±${accuracy.toStringAsFixed(1)} m'}. It must be ±25 m or better. Retry your location.';
    }
    if (fence != null && !fence!.isInside) {
      return 'Estimated distance is ${formatDistance(fence!.distanceFromCentre)} with ±${accuracy.toStringAsFixed(1)} m accuracy. Approved WFH/remote staff may continue; onsite punches must be within the approved boundary.';
    }
    return null;
  }
}

class PunchController {
  PunchController(this._ref);

  final Ref _ref;

  /// Reads a position and evaluates it against the fence.
  ///
  /// A location failure is returned rather than thrown: the screen still has
  /// something to render, and the person still needs to be told which of the
  /// several location problems they have.
  Future<PunchPreparation> prepare({
    required bool isClockingIn,
    required GeofenceState geofence,
  }) async {
    try {
      final coordinates = await _ref.read(locationServiceProvider).current();
      return PunchPreparation(
        isClockingIn: isClockingIn,
        coordinates: coordinates,
        fence: evaluateFence(
          fenceLatitude: geofence.latitude,
          fenceLongitude: geofence.longitude,
          radiusInMetres: geofence.radiusInMeters,
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
        ),
      );
    } on LocationFailure catch (failure) {
      return PunchPreparation(
        isClockingIn: isClockingIn,
        locationFailure: failure,
      );
    }
  }

  /// Sends the punch, then drops the screens whose data it just changed.
  Future<void> submit(PunchPreparation preparation) async {
    if (preparation.faceImage == null || preparation.faceImage!.isEmpty) {
      throw const ApiUnknown('Camera evidence is required. Take and submit a face photo first.');
    }
    final dio = _ref.read(apiClientProvider).dio;
    final path = preparation.isClockingIn
        ? '/attendance/clock-in/'
        : '/attendance/clock-out/';

    try {
      final response = await dio.post<dynamic>(
        path,
        data: FormData.fromMap({
          if (preparation.coordinates != null) ...{
            'latitude': preparation.coordinates!.latitude,
            'longitude': preparation.coordinates!.longitude,
            'accuracy': preparation.coordinates!.accuracy,
            'location_timestamp': preparation.coordinates!.capturedAt?.millisecondsSinceEpoch,
          },
          'face_image': MultipartFile.fromBytes(
            preparation.faceImage ?? Uint8List(0),
            filename: 'attendance-face.jpg',
          ),
        }),
      );
      // Clock-in answers 200 with {"error": "..."} when the employee has no
      // work information. That is a refusal, not a saved punch.
      final body = response.data;
      final refused = body is Map ? body['error'] : null;
      if (refused is String && refused.trim().isNotEmpty) {
        throw ApiUnknown(refused.trim());
      }
    } on DioException catch (e) {
      final failure = e.error;
      final apiFailure = failure is ApiFailure ? failure : const ApiUnknown();
      // Clock-out's API calls the web view. That view writes the punch, then
      // renders an HTML fragment on a request that has no cookies, and the
      // render throws. The API reports that throw as 400 "Already clocked-out"
      // even though the punch was just saved — which is the banner people see
      // when the hold finishes. Whether they are still clocked in is the fact.
      final savedDespiteError =
          !preparation.isClockingIn &&
          apiFailure.message == 'Already clocked-out' &&
          !await _stillClockedIn();
      if (!savedDespiteError) throw apiFailure;
    }

    // Home and attendance both show punch state; neither is right any more.
    _ref.invalidate(homeProvider);
    _ref.invalidate(attendanceOverviewProvider);
  }

  /// True when a fresh home read still has an open punch.
  ///
  /// A failed read stays "still in": claiming a checkout we could not confirm
  /// is worse than leaving the error on screen.
  Future<bool> _stillClockedIn() async {
    try {
      final home = await _ref.read(homeApiProvider).fetch();
      return home.punch.isClockedIn;
    } on ApiFailure {
      return true;
    }
  }
}

final punchControllerProvider = Provider<PunchController>(PunchController.new);
