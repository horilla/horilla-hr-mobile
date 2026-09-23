/// Geo-fence arithmetic.
///
/// Kept separate from anything that touches hardware so it can be tested
/// properly: distance is pure maths, and it is the part that decides whether
/// someone is allowed to clock in.
///
/// The server is still the authority -- it re-checks the coordinates it is
/// sent and refuses an out-of-fence punch (and, since the fail-closed fix,
/// refuses one it cannot evaluate). This exists so the app can tell someone
/// *before* they tap, rather than after a round trip.
library;

import 'dart:math' as math;

/// Mean Earth radius in metres, which is what geopy's `geodesic` approximates
/// closely enough at fence distances (tens to hundreds of metres).
const double _earthRadiusMetres = 6371008.8;

/// Great-circle distance between two points, in metres.
///
/// Haversine rather than a flat approximation: a flat one is fine at 100 m
/// and wrong near the poles or across the date line, and being wrong about a
/// fence is the whole failure mode here.
double distanceInMetres({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  double radians(double degrees) => degrees * math.pi / 180.0;

  final dLat = radians(toLatitude - fromLatitude);
  final dLon = radians(toLongitude - fromLongitude);
  final lat1 = radians(fromLatitude);
  final lat2 = radians(toLatitude);

  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
  final c = 2 * math.asin(math.min(1, math.sqrt(a)));
  return _earthRadiusMetres * c;
}

/// Where the caller stands relative to the fence.
class FencePosition {
  const FencePosition({
    required this.distanceFromCentre,
    required this.radius,
  });

  final double distanceFromCentre;
  final double radius;

  bool get isInside => distanceFromCentre <= radius;

  /// How far outside, in metres. Zero when inside.
  double get metresOutside =>
      isInside ? 0 : distanceFromCentre - radius;

  /// Short human phrase for the punch screen.
  String get description {
    if (isInside) {
      final remaining = (radius - distanceFromCentre).round();
      return 'Inside the fence · ${remaining}m from its edge';
    }
    return '${metresOutside.round()}m outside the fence';
  }
}

FencePosition? evaluateFence({
  required double? fenceLatitude,
  required double? fenceLongitude,
  required int? radiusInMetres,
  required double latitude,
  required double longitude,
}) {
  if (fenceLatitude == null ||
      fenceLongitude == null ||
      radiusInMetres == null ||
      radiusInMetres <= 0) {
    return null;
  }

  return FencePosition(
    distanceFromCentre: distanceInMetres(
      fromLatitude: fenceLatitude,
      fromLongitude: fenceLongitude,
      toLatitude: latitude,
      toLongitude: longitude,
    ),
    radius: radiusInMetres.toDouble(),
  );
}
