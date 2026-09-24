/// The two pure decisions inside the punch-time presence check, pulled out
/// of the camera/detector plumbing so they can be tested without either --
/// `camera`'s `CameraImage`/`Plane` only have private constructors, so
/// there is no way to build a fake frame from a test at all.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:horilla_mobile/features/facedetection/ui/face_presence_gate.dart';

void main() {
  group('isSupportedCameraFrame', () {
    test('Android NV21, one plane -- supported', () {
      expect(
        isSupportedCameraFrame(
          formatRawValue: InputImageFormat.nv21.rawValue,
          planeCount: 1,
          isAndroid: true,
        ),
        isTrue,
      );
    });

    test('iOS BGRA8888, one plane -- supported', () {
      expect(
        isSupportedCameraFrame(
          formatRawValue: InputImageFormat.bgra8888.rawValue,
          planeCount: 1,
          isAndroid: false,
        ),
        isTrue,
      );
    });

    test(
      'Android multi-plane YUV420 -- not supported, would need concatenating',
      () {
        expect(
          isSupportedCameraFrame(
            formatRawValue: InputImageFormat.yv12.rawValue,
            planeCount: 3,
            isAndroid: true,
          ),
          isFalse,
        );
      },
    );

    test('the wrong single-plane format for the platform is rejected', () {
      // BGRA8888 handed to the Android branch, and vice versa.
      expect(
        isSupportedCameraFrame(
          formatRawValue: InputImageFormat.bgra8888.rawValue,
          planeCount: 1,
          isAndroid: true,
        ),
        isFalse,
      );
      expect(
        isSupportedCameraFrame(
          formatRawValue: InputImageFormat.nv21.rawValue,
          planeCount: 1,
          isAndroid: false,
        ),
        isFalse,
      );
    });

    test('an unrecognised raw format value is rejected, not crashed on', () {
      expect(
        isSupportedCameraFrame(
          formatRawValue: -999,
          planeCount: 1,
          isAndroid: true,
        ),
        isFalse,
      );
      expect(
        isSupportedCameraFrame(
          formatRawValue: null,
          planeCount: 1,
          isAndroid: true,
        ),
        isFalse,
      );
    });
  });

  group('PresenceCounter', () {
    test('confirms only once the run reaches the required length', () {
      final counter = PresenceCounter(requiredConsecutiveFrames: 3);

      expect(counter.record(faceDetected: true), isFalse);
      expect(counter.record(faceDetected: true), isFalse);
      expect(counter.record(faceDetected: true), isTrue);
    });

    test('a single missed frame resets the run', () {
      final counter = PresenceCounter(requiredConsecutiveFrames: 3);

      expect(counter.record(faceDetected: true), isFalse);
      expect(counter.record(faceDetected: true), isFalse);
      expect(counter.record(faceDetected: false), isFalse);
      // The two earlier detections must not count toward this run.
      expect(counter.record(faceDetected: true), isFalse);
      expect(counter.record(faceDetected: true), isFalse);
      expect(counter.record(faceDetected: true), isTrue);
    });

    test('stays confirmed on every subsequent frame with a face', () {
      final counter = PresenceCounter(requiredConsecutiveFrames: 2);

      expect(counter.record(faceDetected: true), isFalse);
      expect(counter.record(faceDetected: true), isTrue);
      expect(counter.record(faceDetected: true), isTrue);
    });
  });
}
