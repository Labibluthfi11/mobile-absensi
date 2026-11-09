import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/services/face_detection_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('attendance face validation before upload', () {
    late Directory tempDirectory;
    late File photo;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('attendance-face-');
      photo = File(path.join(tempDirectory.path, 'selfie.jpg'));
      await photo.writeAsBytes([1, 2, 3]);
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test('uploads the same photo when a face is detected', () async {
      final detector = _FakeFaceDetectionService(
        faces: const [Rect.fromLTWH(10, 20, 100, 120)],
      );
      File? uploadedPhoto;

      final result = await validateFaceThenUpload(
        photo: photo,
        createDetector: () => detector,
        upload: (file) async {
          uploadedPhoto = file;
          return {'success': true};
        },
      );

      expect(result['success'], isTrue);
      expect(uploadedPhoto?.path, photo.path);
      expect(detector.closed, isTrue);
    });

    test('does not upload when no face is detected', () async {
      final detector = _FakeFaceDetectionService(faces: const []);
      var uploadCalled = false;

      final result = await validateFaceThenUpload(
        photo: photo,
        createDetector: () => detector,
        upload: (_) async {
          uploadCalled = true;
          return {'success': true};
        },
      );

      expect(result['success'], isFalse);
      expect(result['faceNotDetected'], isTrue);
      expect(result['message'], contains('ambil ulang foto'));
      expect(uploadCalled, isFalse);
      expect(detector.closed, isTrue);
    });

    test('does not upload and closes detector when detection fails', () async {
      final detector = _FakeFaceDetectionService(error: StateError('failed'));
      var uploadCalled = false;

      final result = await validateFaceThenUpload(
        photo: photo,
        createDetector: () => detector,
        upload: (_) async {
          uploadCalled = true;
          return {'success': true};
        },
      );

      expect(result['success'], isFalse);
      expect(result['faceDetectionFailed'], isTrue);
      expect(result['message'], contains('Pemeriksaan wajah gagal'));
      expect(uploadCalled, isFalse);
      expect(detector.closed, isTrue);
    });
  });

  group('attendance multipart requests', () {
    late Directory tempDirectory;
    late File photo;
    late _CaptureAdapter adapter;
    late Dio dio;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('attendance-api-');
      photo = File(path.join(tempDirectory.path, 'selfie.jpg'));
      await photo.writeAsBytes([1, 2, 3]);
      adapter = _CaptureAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'))
        ..httpClientAdapter = adapter;
    });

    tearDown(() async {
      dio.close(force: true);
      await tempDirectory.delete(recursive: true);
    });

    test('keeps the check-in endpoint and multipart field names', () async {
      final api = ApiService(dio: dio, storage: _TestSecureStorage());

      await api.absenMasuk(foto: photo, lat: -6.2, lng: 106.8, status: 'hadir');

      final request = adapter.request!;
      final form = request.data as FormData;
      expect(request.uri.path, '/api/v1/absensi/masuk');
      expect(
        form.fields.map((entry) => entry.key),
        containsAll(['lat', 'lng', 'status']),
      );
      expect(form.files.map((entry) => entry.key), contains('foto'));
      final fieldNames = [
        ...form.fields.map((entry) => entry.key),
        ...form.files.map((entry) => entry.key),
      ];
      expect(fieldNames, isNot(contains('has_face')));
      expect(fieldNames, isNot(contains('face_embedding')));
    });

    test(
      'keeps the check-out endpoint and main photo multipart field',
      () async {
        final api = ApiService(dio: dio, storage: _TestSecureStorage());

        await api.absenPulang(foto: photo, lat: -6.2, lng: 106.8);

        final request = adapter.request!;
        final form = request.data as FormData;
        expect(request.uri.path, '/api/v1/absensi/pulang');
        expect(
          form.fields.map((entry) => entry.key),
          containsAll(['lat', 'lng']),
        );
        expect(form.files.map((entry) => entry.key), contains('foto'));
        expect(form.files.map((entry) => entry.key), isNot(contains('foto_2')));
        final fieldNames = [
          ...form.fields.map((entry) => entry.key),
          ...form.files.map((entry) => entry.key),
        ];
        expect(fieldNames, isNot(contains('has_face')));
        expect(fieldNames, isNot(contains('face_embedding')));
      },
    );
  });
}

class _FakeFaceDetectionService implements FaceDetectionService {
  _FakeFaceDetectionService({this.faces = const [], this.error});

  final List<Rect> faces;
  final Object? error;
  bool closed = false;

  @override
  Future<List<Rect>> detectFaces(File image) async {
    if (error != null) throw error!;
    return faces;
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}

class _TestSecureStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;
}

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    await requestStream?.drain<void>();
    return ResponseBody.fromString(
      '{"data":null}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
