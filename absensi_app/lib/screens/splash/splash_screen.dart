// lib/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/screens/auth/login.screen.dart'; // Perbaiki ini jadi login_screen.dart
import 'package:absensi_app/screens/home/home.screen.dart'; // Perbaiki ini jadi home_screen.dart

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _logoSlideAnimation;

  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 700));

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800), // Durasi transisi
        pageBuilder: (context, animation, secondaryAnimation) {
          // Ini adalah widget yang akan ditampilkan SETELAH splash screen
          if (authProvider.isAuthenticated) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
        // --- INI ADALAH BAGIAN YANG HARUS KOSONG / DIHILANGKAN ---
        // Dengan tidak adanya transitionsBuilder, Flutter akan menggunakan transisi default.
        // Jadi, Splash Screen akan memudar (karena pushReplacement), dan layar baru muncul normal.
        // Tidak ada lagi kode transitionsBuilder di sini!
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color dustyLatte100 = const Color(0xFFF4F0EB);
    final Color dustyLatte400 = const Color(0xFFD4C8B5);

    final List<Color> gradientColors = [
      dustyLatte400,
      dustyLatte100,
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _logoSlideAnimation,
                child: FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 220,
                      height: 220,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SlideTransition(
                position: _textSlideAnimation,
                child: FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Absensi Pintar',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mudah, Cepat, Akurat',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}