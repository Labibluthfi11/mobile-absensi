// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/screens/auth/login.screen.dart';
import 'package:absensi_app/screens/home/home.screen.dart';
import 'package:absensi_app/screens/splash/splash_screen.dart'; // <--- IMPORT SPLASH SCREEN DI SINI

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AbsensiProvider()),
      ],
      child: MyApp(),
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
        // ... kode tema Anda ...
      ),
      darkTheme: ThemeData.dark().copyWith(
        // ... kode darkTheme Anda ...
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(), // <--- UBAH INI JADI SPLASHSCREEN
      // Logika Consumer untuk AuthProvider sekarang akan berada di dalam SplashScreen
      // untuk menentukan navigasi selanjutnya.
    );
  }
}