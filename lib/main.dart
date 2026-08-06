import 'package:absensi_app/screens/home/absensi_pulang_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:absensi_app/services/notification_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// === Import service & provider ===
import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/providers/izin_keluar_provider.dart';

// === Import screens utama ===
import 'package:absensi_app/screens/auth/login.screen.dart';
import 'package:absensi_app/screens/auth/register.screen.dart';
import 'package:absensi_app/screens/home/home.screen.dart';
import 'package:absensi_app/screens/splash/splash_screen.dart';

// === Import halaman tambahan untuk navigasi dari notifikasi ===
import 'package:absensi_app/pages/notifications_page.dart';
import 'package:absensi_app/screens/home/absensi_sakit_form_screen.dart';
import 'package:absensi_app/screens/home/jadwal_lembur_screen.dart';
import 'package:absensi_app/screens/home/absensi_lembur_screen.dart';
import 'package:absensi_app/services/security_service.dart';
import 'package:absensi_app/screens/security/device_not_secure_screen.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init(
    (options) {
      // Masukkan DSN Sentry lu di sini nanti bang
      options.dsn = 'https://ec1c6b4670ff0903c80a5308f638b0fe@o4511295361187840.ingest.us.sentry.io/4511295414468608'; 
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      await Firebase.initializeApp();
      await NotificationService().initialize();
      await initializeDateFormatting('id_ID', null);

      // 🔥 VALIDASI KEAMANAN PERANGKAT (ROOT/EMULATOR)
      final securityStatus = await SecurityService.checkDeviceSecurity();
      if (!securityStatus['isSafe']) {
        runApp(DeviceNotSecureScreen(message: securityStatus['message']));
        return;
      }

      try {
        cameras = await availableCameras();
      } on CameraException catch (e) {
        print('Error initializing cameras: ${e.description}');
        cameras = [];
      }

      runApp(
        MultiProvider(
          providers: [
            Provider<ApiService>(
              create: (_) => ApiService(),
            ),
            ChangeNotifierProvider(
              create: (context) => AuthProvider(
                apiService: context.read<ApiService>(),
              ),
            ),
            ChangeNotifierProvider(
              create: (context) => AbsensiProvider(
                apiService: context.read<ApiService>(),
              ),
            ),
            ChangeNotifierProvider(
              create: (context) => IzinKeluarProvider(
                apiService: context.read<ApiService>(),
              ),
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = context.read<ApiService>();

    return MaterialApp(
      title: 'Absensi App',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        SentryNavigatorObserver(),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(title: 'Absensi App'),

      // 🧭 Semua route lengkap
     routes: {
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/home': (context) => const HomeScreen(),
  '/notifications': (context) => NotificationsPage(apiService: apiService),

  // === Rute dari notifikasi ===
  '/lembur_detail': (context) => const AbsensiLemburScreen(),
  '/lembur': (context) => const AbsensiLemburScreen(),
  '/sakit_detail': (context) => const SakitFormScreen(),
  '/izin_detail': (context) => const SakitFormScreen(),

  // ✅ Tambahkan ini biar gak error lagi
  '/absensi_detail': (context) => const AbsensiPulangScreen(),
  '/jadwal_lembur': (context) => const JadwalLemburScreen(),
},

    );
  }
}
