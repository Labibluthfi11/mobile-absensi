import 'dart:convert';
import 'dart:typed_data';

import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/models/historical_attendance_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_io/io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('historical attendance request validation', () {
    final now = DateTime(2026, 11, 6, 15, 0);
    final date = DateTime(2026, 11, 4);

    test(
      'requires an allowed request type and rejects single-sided absence',
      () {
        for (final type in ['lupa_masuk', 'lupa_pulang', 'invalid']) {
          expect(_request(type, date: date).validate(now: now), isNotEmpty);
        }
        expect(HistoricalAttendanceRequest.jenisPengajuanYangDiizinkan, {
          'lupa_keduanya',
          'izin',
          'sakit',
        });
      },
    );

    test('requires proof image and valid description', () {
      final errors = _request(
        'sakit',
        date: date,
        missingFile: true,
        keterangan: 'x',
      ).validate(now: now);
      expect(errors['file_bukti'], isNotNull);
      expect(errors['keterangan'], isNotNull);
    });

    test('only accepts dates in the previous 30 days, not today or future', () {
      expect(
        _request('sakit', date: DateTime(2026, 10, 7)).validate(now: now),
        isEmpty,
      );
      expect(
        _request(
          'sakit',
          date: DateTime(2026, 10, 6),
        ).validate(now: now)['tanggal'],
        isNotNull,
      );
      expect(
        _request(
          'sakit',
          date: DateTime(2026, 11, 6),
        ).validate(now: now)['tanggal'],
        isNotNull,
      );
      expect(
        _request(
          'sakit',
          date: DateTime(2026, 11, 7),
        ).validate(now: now)['tanggal'],
        isNotNull,
      );
    });

    test('validates paired hours, order, and future checkout time', () {
      expect(
        _request(
          'lupa_keduanya',
          date: date,
          jamMasuk: '08:30',
          jamPulang: '17:00',
        ).validate(now: now),
        isEmpty,
      );
      expect(
        _request(
          'lupa_keduanya',
          date: date,
          jamMasuk: '17:00',
          jamPulang: '08:30',
        ).validate(now: now)['jam_pulang'],
        isNotNull,
      );
      expect(
        _request(
          'lupa_keduanya',
          date: date,
          jamMasuk: '08:30',
          jamPulang: '25:30',
        ).validate(now: now)['jam_pulang'],
        isNotNull,
      );
      expect(
        _request(
          'lupa_keduanya',
          date: DateTime(2026, 11, 6),
          jamMasuk: '08:30',
          jamPulang: '17:00',
        ).validate(now: now)['jam_pulang'],
        isNotNull,
      );
    });

    test('requires allowed leave type for organic employees only', () {
      expect(
        _request(
          'izin',
          date: date,
          employmentType: 'organik',
        ).validate(now: now)['jenis_izin'],
        isNotNull,
      );
      expect(
        _request(
          'izin',
          date: date,
          employmentType: 'organik',
          jenisIzin: 'cuti_tahunan',
        ).validate(now: now),
        isEmpty,
      );
      expect(
        _request(
          'sakit',
          date: date,
          employmentType: 'organik',
        ).validate(now: now),
        isEmpty,
      );
    });
  });

  group('historical attendance multipart API', () {
    late Directory directory;
    late File photo;
    late _CaptureAdapter adapter;
    late ApiService api;
    late Dio dio;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'historical-attendance-',
      );
      photo = File('${directory.path}\\proof.jpg');
      await photo.writeAsBytes([1, 2, 3]);
      adapter = _CaptureAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'))
        ..httpClientAdapter = adapter;
      api = ApiService(dio: dio, storage: _TestSecureStorage());
    });

    tearDown(() async {
      dio.close(force: true);
      await directory.delete(recursive: true);
    });

    for (final type in ['lupa_keduanya', 'izin', 'sakit']) {
      test('uploads $type using the approved contract fields', () async {
        final request = _request(
          type,
          date: DateTime.now().subtract(const Duration(days: 2)),
          file: photo,
          employmentType: type == 'izin' ? 'organik' : 'freelance',
          jenisIzin: 'cuti_tahunan',
        );

        final result = await api.ajukanAbsensiLampau(request: request);

        expect(result['success'], isTrue);
        expect(adapter.request?.method, 'POST');
        expect(adapter.request?.path, 'absensi/pengajuan-lampau');
        expect(
          adapter.request?.headers[Headers.contentTypeHeader],
          startsWith('multipart/form-data'),
        );
        final fieldNames = RegExp(
          r'Content-Disposition: form-data; name="([^"]+)"',
          caseSensitive: false,
        ).allMatches(adapter.body).map((match) => match.group(1)).toSet();
        final expectedFields = <String>{
          'jenis_pengajuan',
          'tanggal',
          'keterangan',
          'file_bukti',
        };
        if (type == 'lupa_keduanya') {
          expectedFields.addAll({'jam_masuk', 'jam_pulang'});
        } else if (type == 'izin') {
          expectedFields.add('jenis_izin');
        }
        expect(fieldNames, expectedFields);
        expect(adapter.body, contains('jenis_pengajuan'));
        expect(adapter.body, contains(type));
        expect(adapter.body, contains('tanggal'));
        expect(adapter.body, contains('keterangan'));
        expect(adapter.body, contains('file_bukti'));
        expect(adapter.body, contains('proof.jpg'));
        expect(
          adapter.request?.headers['Authorization'],
          startsWith('Bearer '),
        );

        if (type == 'lupa_keduanya') {
          expect(adapter.body, contains('jam_masuk'));
          expect(adapter.body, contains('jam_pulang'));
          expect(adapter.body, isNot(contains('jenis_izin')));
        } else if (type == 'izin') {
          expect(adapter.body, contains('jenis_izin'));
          expect(adapter.body, contains('cuti_tahunan'));
          expect(adapter.body, isNot(contains('jam_masuk')));
        } else {
          expect(adapter.body, isNot(contains('jenis_izin')));
          expect(adapter.body, isNot(contains('jam_masuk')));
        }
        expect(adapter.body, isNot(contains('lupa_masuk')));
        expect(adapter.body, isNot(contains('lupa_pulang')));
      });
    }

    test(
      'rejects missing proof and unsupported single-sided types before upload',
      () async {
        final noProof = _request(
          'sakit',
          date: DateTime.now().subtract(const Duration(days: 1)),
          missingFile: true,
        );
        final noProofResult = await api.ajukanAbsensiLampau(request: noProof);
        expect(noProofResult['success'], isFalse);
        expect(noProofResult['statusCode'], 422);
        expect(
          (noProofResult['data'] as Map)['errors'],
          contains('file_bukti'),
        );
        expect(adapter.request, isNull);
      },
    );

    test('rejects proof images larger than 2 MB', () async {
      final oversized = File('${directory.path}\\large.png');
      await oversized.writeAsBytes(List<int>.filled(2 * 1024 * 1024 + 1, 0));
      final result = await api.ajukanAbsensiLampau(
        request: _request(
          'sakit',
          date: DateTime.now().subtract(const Duration(days: 1)),
          file: oversized,
        ),
      );

      expect(result['success'], isFalse);
      expect(result['statusCode'], 422);
      expect((result['data'] as Map)['errors'], contains('file_bukti'));
      expect(adapter.request, isNull);

      final invalidType = _request(
        'lupa_masuk',
        date: DateTime.now().subtract(const Duration(days: 1)),
      );
      final invalidTypeResult = await api.ajukanAbsensiLampau(
        request: invalidType,
      );
      expect(invalidTypeResult['success'], isFalse);
      expect(adapter.request, isNull);
    });

    test('preserves backend 422 field errors', () async {
      adapter.statusCode = 422;
      adapter.responseData = {
        'message': 'Data tidak valid.',
        'errors': {
          'tanggal': ['Tanggal sudah memiliki absensi.'],
          'keterangan': ['Keterangan terlalu pendek.'],
        },
      };

      final result = await api.ajukanAbsensiLampau(
        request: _request(
          'sakit',
          date: DateTime.now().subtract(const Duration(days: 1)),
          file: photo,
        ),
      );

      expect(result['success'], isFalse);
      expect(result['statusCode'], 422);
      expect((result['data'] as Map)['errors'], contains('tanggal'));
      expect((result['data'] as Map)['errors'], contains('keterangan'));
    });

    test('preserves backend conflict message for HTTP 409', () async {
      adapter.statusCode = 409;
      adapter.responseData = {
        'message': 'Sudah ada pengajuan untuk tanggal tersebut.',
      };

      final result = await api.ajukanAbsensiLampau(
        request: _request(
          'sakit',
          date: DateTime.now().subtract(const Duration(days: 1)),
          file: photo,
        ),
      );

      expect(result['success'], isFalse);
      expect(result['statusCode'], 409);
      expect(result['message'], 'Sudah ada pengajuan untuk tanggal tersebut.');
    });
  });
}

HistoricalAttendanceRequest _request(
  String type, {
  required DateTime date,
  File? file,
  String keterangan = 'Keterangan pengajuan absensi',
  String employmentType = 'freelance',
  String? jamMasuk = '08:00',
  String? jamPulang = '17:00',
  String? jenisIzin,
  bool missingFile = false,
}) {
  return HistoricalAttendanceRequest(
    jenisPengajuan: type,
    tanggal: date,
    keterangan: keterangan,
    fileBukti: missingFile ? null : file ?? File('proof.jpg'),
    employmentType: employmentType,
    jamMasuk: jamMasuk,
    jamPulang: jamPulang,
    jenisIzin: jenisIzin,
  );
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
  }) async => 'test-token';
}

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? request;
  String body = '';
  int statusCode = 201;
  Object? responseData = const {'message': 'Pengajuan menunggu persetujuan.'};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    final bytes =
        await requestStream?.fold<List<int>>(
          <int>[],
          (previous, chunk) => previous..addAll(chunk),
        ) ??
        <int>[];
    body = utf8.decode(bytes);
    return ResponseBody.fromString(
      jsonEncode(responseData),
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
