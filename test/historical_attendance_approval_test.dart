import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/screens/home/attendance_history_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('shows historical attendance as pending until approval', (
    tester,
  ) async {
    final absensi = Absensi.fromJson({
      'id': 42,
      'user_id': 7,
      'status': 'hadir',
      'tipe': 'lupa_keduanya',
      'status_approval': 'pending',
      'check_in_at': '2026-10-12T08:00:00',
      'check_out_at': '2026-10-12T17:00:00',
    });

    await _pumpHistory(tester, [absensi]);

    expect(find.text('DI PROSES'), findsOneWidget);
    expect(find.text('HADIR'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows historical attendance approved after admin approval', (
    tester,
  ) async {
    final absensi = Absensi.fromJson({
      'id': 42,
      'user_id': 7,
      'status': 'hadir',
      'tipe': 'lupa_keduanya',
      'status_approval': 'approved',
      'check_in_at': '2026-10-12T08:00:00',
      'check_out_at': '2026-10-12T17:00:00',
    });

    await _pumpHistory(tester, [absensi]);

    expect(find.text('DISETUJUI'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _pumpHistory(WidgetTester tester, List<Absensi> records) async {
  SharedPreferences.setMockInitialValues({});
  final api = _HistoryApiService(records);
  final auth = AuthProvider(apiService: api, storage: _TestSecureStorage());
  await auth.initializationFuture;
  final attendance = AbsensiProvider(apiService: api);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<AbsensiProvider>.value(value: attendance),
      ],
      child: const MaterialApp(home: AttendanceHistoryScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
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
  }) async {
    return key == 'auth_token' ? 'test-token' : null;
  }
}

class _HistoryApiService extends ApiService {
  _HistoryApiService(this.records)
    : super(dio: Dio(), storage: _TestSecureStorage());

  final List<Absensi> records;

  @override
  Future<List<Absensi>> getHistoryAbsensi({
    String? searchDate,
    int? month,
    int? year,
  }) async {
    return records;
  }
}
