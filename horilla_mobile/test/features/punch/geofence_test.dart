/// Geo-fence arithmetic.
///
/// This decides whether someone may clock in, so it gets real distances
/// rather than round numbers. The server re-checks everything it is sent --
/// the point of this code is to tell a person before they tap rather than
/// after a round trip, so it has to agree with the server's answer.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:horilla_mobile/features/punch/data/geofence.dart';

void main() {
  group('distance', () {
    test('the same point is zero metres away', () {
      expect(
        distanceInMetres(
          fromLatitude: 12.9716,
          fromLongitude: 77.5946,
          toLatitude: 12.9716,
          toLongitude: 77.5946,
        ),
        closeTo(0, 0.001),
      );
    });

    test('a known short hop is right to within a metre', () {
      // 0.001 degrees of latitude is ~111.2 m anywhere on Earth.
      expect(
        distanceInMetres(
          fromLatitude: 12.9716,
          fromLongitude: 77.5946,
          toLatitude: 12.9726,
          toLongitude: 77.5946,
        ),
        closeTo(111.2, 1),
      );
    });

    test('a known long distance is right to within a kilometre', () {
      // Bengaluru to Kochi. Checked against the components rather than a
      // remembered figure: 3.0404 deg of latitude is ~338 km, and 1.3273 deg
      // of longitude at ~11.5 deg latitude is ~145 km, so the great-circle
      // distance is sqrt(338^2 + 145^2) ~= 368 km.
      final metres = distanceInMetres(
        fromLatitude: 12.9716,
        fromLongitude: 77.5946,
        toLatitude: 9.9312,
        toLongitude: 76.2673,
      );
      expect(metres / 1000, closeTo(367.7, 1));
    });

    test('longitude distance shrinks away from the equator', () {
      // A flat approximation gets this wrong, which is why this is haversine.
      final atEquator = distanceInMetres(
        fromLatitude: 0,
        fromLongitude: 0,
        toLatitude: 0,
        toLongitude: 1,
      );
      final farNorth = distanceInMetres(
        fromLatitude: 60,
        fromLongitude: 0,
        toLatitude: 60,
        toLongitude: 1,
      );
      expect(farNorth, lessThan(atEquator / 1.9));
    });

    test('crossing the date line is a short hop, not a trip round the world', () {
      final metres = distanceInMetres(
        fromLatitude: 0,
        fromLongitude: 179.999,
        toLatitude: 0,
        toLongitude: -179.999,
      );
      expect(metres, lessThan(500));
    });
  });

  group('fence position', () {
    FencePosition at(double distance, {double radius = 100}) =>
        FencePosition(distanceFromCentre: distance, radius: radius);

    test('inside the radius is inside', () {
      expect(at(40).isInside, isTrue);
      expect(at(40).metresOutside, 0);
    });

    test('exactly on the edge counts as inside', () {
      // The server uses `distance <= radius`; disagreeing here would mean
      // refusing a punch the server would have accepted.
      expect(at(100).isInside, isTrue);
    });

    test('beyond the radius is outside, and says by how much', () {
      final position = at(140);
      expect(position.isInside, isFalse);
      expect(position.metresOutside, closeTo(40, 0.001));
      expect(position.description, contains('40m outside'));
    });

    test('inside reports the distance to the edge, not to the centre', () {
      expect(at(40).description, contains('60m'));
    });
  });

  group('evaluating a fence', () {
    test('an unconfigured fence yields nothing to check', () {
      expect(
        evaluateFence(
          fenceLatitude: null,
          fenceLongitude: null,
          radiusInMetres: null,
          latitude: 12.9716,
          longitude: 77.5946,
        ),
        isNull,
      );
    });

    test('a zero or negative radius is treated as unconfigured', () {
      // Rather than as a fence nobody can ever be inside, which would lock
      // every employee out of clocking in.
      expect(
        evaluateFence(
          fenceLatitude: 12.9716,
          fenceLongitude: 77.5946,
          radiusInMetres: 0,
          latitude: 12.9716,
          longitude: 77.5946,
        ),
        isNull,
      );
    });

    test('standing at the office is inside', () {
      final position = evaluateFence(
        fenceLatitude: 12.9716,
        fenceLongitude: 77.5946,
        radiusInMetres: 150,
        latitude: 12.9716,
        longitude: 77.5946,
      )!;
      expect(position.isInside, isTrue);
    });

    test('standing a city away is outside', () {
      final position = evaluateFence(
        fenceLatitude: 12.9716,
        fenceLongitude: 77.5946,
        radiusInMetres: 150,
        latitude: 9.9312,
        longitude: 76.2673,
      )!;
      expect(position.isInside, isFalse);
    });
  });
}
