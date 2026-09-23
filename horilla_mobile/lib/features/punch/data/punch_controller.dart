/// Preparing and submitting a punch.
///
/// The whole flow lives here rather than in the widget so it can be tested
/// without hardware: read a position, work out where that is relative to the
/// fence, then submit. Only [LocationService] touches the device, and it is
/// injected.
library;

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
  });

  final bool isClockingIn;
  final Coordinates? coordinates;
  final FencePosition? fence;
  final LocationFailure? locationFailure;

  /// Whether the punch button should be live.
  ///
  /// The handoff requires the fence state to be resolved before the button
  /// enables. Where a fence is enforced and the person is outside it, the app
  /// does not offer a button that the server will refuse -- being told "no"
  /// before tapping is better than after.
  bool get canSubmit {
    if (locationFailure != null) return false;
    if (fence == null) return true; // no fence configured, or not required
    return fence!.isInside;
  }

  String? get blockedReason {
    if (locationFailure != null) return locationFailure!.message;
    if (fence != null && !fence!.isInside) {
      return 'You are ${fence!.metresOutside.round()}m outside your '
          'workplace. Move closer to clock '
          '${isClockingIn ? 'in' : 'out'}.';
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
    if (!geofence.enabled) {
      // No fence, so no reason to ask for a location the server will not use.
      return PunchPreparation(isClockingIn: isClockingIn);
    }

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
    final dio = _ref.read(apiClientProvider).dio;
    final path = preparation.isClockingIn
        ? '/attendance/clock-in/'
        : '/attendance/clock-out/';

    try {
      await dio.post<dynamic>(
        path,
        data: {
          // Sent when there is a fence; the server re-checks them and is the
          // authority. Omitted entirely when there is no fence, rather than
          // sent as nulls the server would have to interpret.
          if (preparation.coordinates != null) ...{
            'latitude': preparation.coordinates!.latitude,
            'longitude': preparation.coordinates!.longitude,
          },
        },
      );
    } on DioException catch (e) {
      final failure = e.error;
      throw failure is ApiFailure ? failure : const ApiUnknown();
    }

    // Home and attendance both show punch state; neither is right any more.
    _ref.invalidate(homeProvider);
    _ref.invalidate(attendanceOverviewProvider);
  }
}

final punchControllerProvider =
    Provider<PunchController>(PunchController.new);
