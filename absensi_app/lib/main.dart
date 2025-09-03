import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/screens/auth/login.screen.dart';
import 'package:absensi_app/screens/auth/register.screen.dart';
import 'package:absensi_app/screens/home/home.screen.dart';
import 'package:absensi_app/screens/splash/splash_screen.dart';
import 'package:absensi_app/screens/home/absensi_camera_screen.dart';
// Tidak perlu mengimpor AbsensiSakitFormScreen di sini karena tidak digunakan di MaterialApp.routes

// Variabel global untuk kamera (diinisialisasi sebelum runApp)
late List<CameraDescription> cameras;

void main() async {
  // Pastikan Flutter binding sudah diinisialisasi sebelum mengakses kamera
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi data lokal untuk DateFormat
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi daftar kamera yang tersedia
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error initializing cameras: ${e.description}');
    cameras = [];
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AbsensiProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Tambahkan tema lainnya
        appBarTheme: const AppBarTheme(
          color: Colors.deepPurple,
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        // Rute ini berfungsi untuk navigasi ke layar kamera.
        '/camera': (context) => const AbsensiCameraScreen(),
        // Rute untuk '/sakit_form' dihapus karena sekarang navigasinya
        // dilakukan secara langsung dari AbsensiCameraScreen dengan membawa data.
      },
    );
  }
}
