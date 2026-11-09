import 'dart:ui';

import 'package:absensi_app/services/face_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasClearlyDetectedFace', () {
    test('rejects a photo when no face is detected', () {
      expect(hasClearlyDetectedFace(const <Rect>[]), isFalse);
    });

    test('accepts a photo when a face has a visible bounding box', () {
      expect(
        hasClearlyDetectedFace(const [Rect.fromLTWH(20, 30, 120, 140)]),
        isTrue,
      );
    });

    test('rejects invalid empty face bounds', () {
      expect(
        hasClearlyDetectedFace(const [Rect.fromLTWH(20, 30, 0, 0)]),
        isFalse,
      );
    });
  });
}
