import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:universal_io/io.dart';

abstract interface class FaceDetectionService {
  Future<List<Rect>> detectFaces(File image);
  Future<void> close();
}

class MlKitFaceDetectionService implements FaceDetectionService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );

  @override
  Future<List<Rect>> detectFaces(File image) async {
    final faces = await _detector.processImage(
      InputImage.fromFilePath(image.path),
    );
    return faces.map((face) => face.boundingBox).toList(growable: false);
  }

  @override
  Future<void> close() => _detector.close();
}

bool hasClearlyDetectedFace(Iterable<Rect> faces) {
  return faces.any((face) => face.width > 0 && face.height > 0);
}

Future<Map<String, dynamic>> validateFaceThenUpload({
  required File photo,
  required FaceDetectionService Function() createDetector,
  required Future<Map<String, dynamic>> Function(File photo) upload,
}) async {
  FaceDetectionService? detector;
  List<Rect>? faces;
  Object? detectionError;

  try {
    detector = createDetector();
    faces = await detector.detectFaces(photo);
  } catch (error) {
    detectionError = error;
  }

  if (detector != null) {
    try {
      await detector.close();
    } catch (error) {
      detectionError ??= error;
    }
  }

  if (detectionError != null) {
    debugPrint('Pemeriksaan wajah gagal: $detectionError');
    return {
      'success': false,
      'faceDetectionFailed': true,
      'message':
          'Pemeriksaan wajah gagal. Foto tidak diunggah; silakan ambil ulang foto dan coba lagi.',
    };
  }

  if (faces == null || !hasClearlyDetectedFace(faces)) {
    return {
      'success': false,
      'faceNotDetected': true,
      'message':
          'Wajah belum terdeteksi. Foto tidak diunggah; silakan ambil ulang foto dengan wajah terlihat jelas.',
    };
  }

  return upload(photo);
}
