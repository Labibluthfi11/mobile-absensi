import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:intl/date_symbol_data_local.dart';

// === Import service & provider ===
import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';

// === Import screens utama ===
import 'package:absensi_app/screens/auth/login.screen.dart';
import 'package:absensi_app/screens/auth/register.screen.dart';
import 'package:absensi_app/screens/home/home.screen.dart';
import 'package:absensi_app/screens/splash/splash_screen.dart';

// === Import halaman tambahan untuk navigasi dari notifikasi ===
import 'package:absensi_app/pages/notifications_page.dart';
import 'package:absensi_app/screens/home/absensi_pulang_screen.dart';
import 'package:absensi_app/screens/home/absensi_sakit_form_screen.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

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
      ],
      child: const MyApp(),
    ),
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          color: Colors.deepPurple,
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),

      // 🧭 Semua route lengkap
     routes: {
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/home': (context) => const HomeScreen(),
  '/notifications': (context) => NotificationsPage(apiService: apiService),

  // === Rute dari notifikasi ===
  '/lembur_detail': (context) => const AbsensiPulangScreen(),
  '/sakit_detail': (context) => const SakitFormScreen(),
  '/izin_detail': (context) => const SakitFormScreen(),

  // ✅ Tambahkan ini biar gak error lagi
  '/absensi_detail': (context) => const AbsensiPulangScreen(),
},

    );
  }
}
