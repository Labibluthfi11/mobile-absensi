import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/screens/auth/login.screen.dart';
import 'package:absensi_app/screens/home/home.screen.dart';

// Definisi warna yang digunakan dari video
const Color _primaryColor = Color(0xFF003366);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _text1Animation;
  late Animation<double> _text2Animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Animasi untuk logo (skala dan fade-in)
    _logoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    // Animasi untuk teks pertama ("PT ANSEL MUDA BERKARYA")
    _text1Animation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
    );

    // Animasi untuk teks kedua ("Ansel For You")
    _text2Animation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _startAnimationsAndNavigation();
  }

  Future<void> _startAnimationsAndNavigation() async {
    _animationController.forward();
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);

    if (authProvider.isLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Provider.of<AuthProvider>(context, listen: false).isLoading;
      });
    }

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      await absensiProvider.fetchMyAbsensi();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Menggunakan nama file logo yang benar
                ScaleTransition(
                  scale: _logoAnimation,
                  child: Opacity(
                    opacity: _logoAnimation.value,
                    child: Image.asset(
                      'assets/images/ansel-biru.png',
                      width: 200, // Ukuran logo, bisa disesuaikan
                      height: 200,
                    ),
                  ),
                ),
                const SizedBox(width: 15), // Jarak antara logo dan teks
                // Teks "PT ANSEL MUDA BERKARYA"
                FadeTransition(
                  opacity: _text1Animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0), // Animasi dari kanan
                      end: Offset.zero,
                    ).animate(_text1Animation),
                    child: Text(
                      'PT ANSEL\nMUDA\nBERKARYA',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Teks "Ansel For You"
            FadeTransition(
              opacity: _text2Animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(_text2Animation),
                child: Text(
                  'Ansel For You',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
