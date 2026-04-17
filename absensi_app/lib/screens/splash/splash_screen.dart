import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  final String title;

  const SplashScreen({super.key, required this.title});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  // Controller for infinite floating elements
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    // 1. Setup floating background animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    // 2. Setup main logo reveal animation (Staggered)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Bouncy scale for the logo card
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.05).chain(CurveTween(curve: Curves.easeOutBack)), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6)));

    // Fade in
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.8, curve: Curves.easeIn)),
    );

    // Slide up text
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic)),
    );

    _mainController.forward();

    // Redirect after 3.5 seconds
    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pure Indigo Brand Color for that Super-App feel
    const Color brandColor = Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: brandColor,
      body: Stack(
        children: [
          // ================= BACKGROUND ANIMATED ELEMENTS =================
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Top right floating blob
                  Positioned(
                    top: -100 + (30 * math.sin(_floatController.value * math.pi)),
                    right: -50,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Bottom left floating blob
                  Positioned(
                    bottom: -80 + (20 * math.cos(_floatController.value * math.pi)),
                    left: -80,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.03),
                      ),
                    ),
                  ),
                  // Center glowing flare
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 400,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.transparent,
                          ],
                          radius: 0.6,
                        ),
                      ),
                    ),
                  )
                ],
              );
            },
          ),

          // ================= FOREGROUND CONTENT =================
          SafeArea(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Center Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo Glassmorphic Container
                          Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Opacity(
                              opacity: _scaleAnimation.value.clamp(0.0, 1.0),
                              child: Container(
                                height: 140,
                                width: 140,
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(35), // Rounded squircle super-app style
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.2),
                                      blurRadius: 0,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.location_on_rounded, size: 70, color: brandColor),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Typography Area
                          Opacity(
                            opacity: _opacityAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: const Column(
                                children: [
                                  Text(
                                    'Absensi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Poppins',
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'ENTERPRISE WORKFORCE',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      letterSpacing: 4.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Loading & Branding
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Column(
                          children: [
                            const _PremiumLoadingDots(),
                            const SizedBox(height: 24),
                            Text(
                              'Powered by Advanced Technology',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// PREMIUM DOT LOADING TWEAKED FOR BLUE BACKGROUND
// ======================================================================
class _PremiumLoadingDots extends StatefulWidget {
  const _PremiumLoadingDots();
  @override
  State<_PremiumLoadingDots> createState() => _PremiumLoadingDotsState();
}
class _PremiumLoadingDotsState extends State<_PremiumLoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_ctrl.value - delay) % 1.0;
            final curve = math.sin(t * math.pi); // 0 to 1 to 0
            final offset = curve * 8.0;
            final scale = 1.0 + (curve * 0.4);

            return Transform.translate(
              offset: Offset(0, -offset),
              child: Transform.scale(
                scale: t >= 0 ? scale : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    width: 7, 
                    height: 7, 
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), 
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 6 * curve,
                          spreadRadius: 1 * curve,
                        )
                      ]
                    )
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
