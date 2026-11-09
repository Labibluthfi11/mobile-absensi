import 'dart:convert';
import 'dart:typed_data';

import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'package:absensi_app/models/user_model.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/providers/izin_keluar_provider.dart';
import 'package:absensi_app/screens/home/home.screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('leave balance parsing', () {
    test(
      'maps root profile id and employment type and parses numeric values',
      () {
        final user = User.fromJson({
          'id': 42,
          'employment_type': 'organik',
          'sisa_cuti': 7.0,
          'tahun_cuti': 2026,
        });

        expect(user.id, 42);
        expect(user.employmentType, 'organik');
        expect(user.sisaCuti, 7);
        expect(user.tahunCuti, 2026);
      },
    );

    test('keeps missing, null, and invalid leave balances null', () {
      expect(User.fromJson(_profile()).sisaCuti, isNull);
      expect(User.fromJson(_profile()..['sisa_cuti'] = null).sisaCuti, isNull);
      expect(
        User.fromJson(_profile()..['sisa_cuti'] = 'not-a-number').sisaCuti,
        isNull,
      );
      expect(User.fromJson(_profile()..['sisa_cuti'] = '8.5').sisaCuti, isNull);
      expect(User.fromJson(_profile()..['sisa_cuti'] = '9.0').sisaCuti, 9);
    });
  });

  test(
    'profile refresh sends Bearer auth and parses root JSON response',
    () async {
      SharedPreferences.setMockInitialValues({});
      final adapter = _ProfileAdapter({
        'id': 42,
        'employment_type': 'organik',
        'sisa_cuti': 5,
        'tahun_cuti': 2026,
      });
      final apiService = ApiService(
        dio: Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'))
          ..httpClientAdapter = adapter,
        storage: _MemorySecureStorage('local-test-credential'),
      );

      final user = await apiService.getAuthenticatedUser();

      expect(adapter.request?.path, 'user');
      expect(
        adapter.request?.headers['Authorization'],
        'Bearer local-test-credential',
      );
      expect(user?.id, 42);
      expect(user?.employmentType, 'organik');
      expect(user?.sisaCuti, 5);
      expect(user?.tahunCuti, 2026);
    },
  );

  test(
    'profile refresh updates provider state and persisted user cache',
    () async {
      SharedPreferences.setMockInitialValues({
        'user_data': jsonEncode(_profile(sisaCuti: 12)),
      });
      final storage = _MemorySecureStorage('local-test-credential');
      final apiService = _ProfileStubApiService(
        User.fromJson(_profile(sisaCuti: 4, tahunCuti: 2026)),
        storage,
      );
      final provider = AuthProvider(apiService: apiService, storage: storage);
      await provider.initializationFuture;

      await provider.refreshProfile();

      final prefs = await SharedPreferences.getInstance();
      final cachedUser = User.fromJson(
        jsonDecode(prefs.getString('user_data')!) as Map<String, dynamic>,
      );
      expect(apiService.profileRequests, 1);
      expect(provider.user?.sisaCuti, 4);
      expect(cachedUser.sisaCuti, 4);
      expect(cachedUser.id, 42);
      expect(cachedUser.employmentType, 'organik');
      expect(cachedUser.tahunCuti, 2026);
    },
  );

  testWidgets(
    'pull-to-refresh requests profile and displays the returned balance',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_data': jsonEncode(_profile(sisaCuti: 12)),
      });
      final storage = _MemorySecureStorage('local-test-credential');
      final apiService = _ProfileStubApiService(
        User.fromJson(_profile(sisaCuti: 8)),
        storage,
      );
      final authProvider = AuthProvider(
        apiService: apiService,
        storage: storage,
      );
      await authProvider.initializationFuture;
      final absensiProvider = AbsensiProvider(apiService: apiService);
      final izinKeluarProvider = IzinKeluarProvider(apiService: apiService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: apiService),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<AbsensiProvider>.value(
              value: absensiProvider,
            ),
            ChangeNotifierProvider<IzinKeluarProvider>.value(
              value: izinKeluarProvider,
            ),
          ],
          child: const MaterialApp(home: HomeContent(checkForUpdates: false)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(apiService.profileRequests, 1);
      expect(find.text('8'), findsOneWidget);

      apiService.profile = User.fromJson(_profile(sisaCuti: 3));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(apiService.profileRequests, 2);
      expect(find.text('3'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Map<String, dynamic> _profile({int? sisaCuti, int? tahunCuti}) => {
  'id': 42,
  'name': 'Test User',
  'email': 'test@example.test',
  'id_karyawan': 'EMP-42',
  'departemen': 'Test',
  'employment_type': 'organik',
  if (sisaCuti != null) 'sisa_cuti': sisaCuti,
  if (tahunCuti != null) 'tahun_cuti': tahunCuti,
};

class _MemorySecureStorage extends FlutterSecureStorage {
  _MemorySecureStorage(this.token);

  final String? token;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return key == 'auth_token' ? token : null;
  }
}

class _ProfileAdapter implements HttpClientAdapter {
  _ProfileAdapter(this.profile);

  final Map<String, dynamic> profile;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(profile),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ProfileStubApiService extends ApiService {
  _ProfileStubApiService(this.profile, FlutterSecureStorage storage)
    : super(dio: Dio(), storage: storage);

  User profile;
  int profileRequests = 0;

  @override
  Future<User?> getAuthenticatedUser() async {
    profileRequests++;
    return profile;
  }

  @override
  Future<List<Absensi>> getHistoryAbsensi({
    String? searchDate,
    int? month,
    int? year,
  }) async {
    return [];
  }

  @override
  Future<int> fetchUnreadCount() async => 0;
}
