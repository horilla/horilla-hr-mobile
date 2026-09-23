/// Getting a position, and the several ways that fails.
///
/// Wrapped behind an interface so everything above it can be tested without
/// hardware. The concrete implementation is the only part of the punch flow
/// that cannot be verified on a machine with no device attached -- which is
/// exactly why the rest is kept out of it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Why a position could not be read. Each needs different words, because each
/// needs a different action from the person holding the phone.
enum LocationProblem {
  /// They said no, but can be asked again.
  denied,

  /// They said never. Only Settings can undo it, so the UI must say so
  /// instead of asking again pointlessly.
  deniedForever,

  /// Location is switched off device-wide.
  servicesDisabled,

  /// A fix could not be obtained in reasonable time -- indoors, tunnels.
  unavailable,
}

class LocationFailure implements Exception {
  const LocationFailure(this.problem, this.message);

  final LocationProblem problem;
  final String message;

  /// Whether asking again could plausibly work.
  bool get isRetryable => problem != LocationProblem.deniedForever;
}

class Coordinates {
  const Coordinates({required this.latitude, required this.longitude, this.accuracy});

  final double latitude;
  final double longitude;

  /// Metres of uncertainty, when the platform reports it.
  final double? accuracy;
}

abstract interface class LocationService {
  Future<Coordinates> current();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<Coordinates> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        LocationProblem.servicesDisabled,
        'Location is switched off on this device. Turn it on to clock in.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationProblem.deniedForever,
        'Location access is blocked for this app. Allow it in Settings to '
        'clock in.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationProblem.denied,
        'Your workplace requires your location to clock in.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // Bounded so a phone that cannot get a fix indoors fails with a
          // message rather than hanging on the confirm button.
          timeLimit: Duration(seconds: 20),
        ),
      );
      return Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } on Exception {
      throw const LocationFailure(
        LocationProblem.unavailable,
        'Could not get your location. Try again somewhere with a clearer '
        'signal.',
      );
    }
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);
