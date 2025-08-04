import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/screens/auth/login.screen.dart';
import 'package:absensi_app/screens/auth/register.screen.dart';
import 'package:absensi_app/screens/home/home.screen.dart';
import 'package:absensi_app/screens/splash/splash_screen.dart';
import 'package:camera/camera.dart'; 

// Variable global untuk kamera (diinisialisasi sebelum runApp)
late List<CameraDescription> cameras;

void main() async {
  // Pastikan Flutter binding sudah diinisialisasi sebelum mengakses kamera
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi daftar kamera yang tersedia
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error initializing cameras: ${e.description}');
    // Handle error, perhaps show a message to the user
    cameras = []; // Set to empty list if no cameras found or error
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
        primarySwatch: Colors.blue, // Contoh warna tema
      ),
      darkTheme: ThemeData.dark(), // Pastikan ini ada jika Anda punya darkTheme
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}