import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/api.service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  late AnimationController _bgAnimController;
  late Animation<Alignment> _topAlignment;
  late Animation<Alignment> _bottomAlignment;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _topAlignment = Tween<Alignment>(begin: Alignment.topLeft, end: Alignment.topRight).animate(_bgAnimController);
    _bottomAlignment = Tween<Alignment>(begin: Alignment.bottomRight, end: Alignment.bottomLeft).animate(_bgAnimController);
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showCustomAlert(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle_outline : Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'))),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        elevation: 8,
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (authProvider.isAuthenticated) {
          if (!mounted) return;
          _showCustomAlert('Login Berhasil! Selamat Datang.', isSuccess: true);
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          if (!mounted) return;
          _showCustomAlert('salah email kalo engga password yaa anak baik coba periksa lagi lebih teliti gitu');
        }
      } catch (e) {
        if (!mounted) return;
        _showCustomAlert('salah email kalo engga password yaa anak baik coba periksa lagi lebih teliti gitu');
      }
    }
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Poppins'),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white.withOpacity(0.8)),
                      onPressed: onVisibilityToggle,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Future<void> _showForgotPasswordPopup() async {
    final apiService = ApiService();
    int step = 1;
    bool isLoading = false;

    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool showNewPassword = false;
    bool showConfirmPassword = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Forgot Password',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)
                          ]
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                step == 1 ? 'Reset Password' : step == 2 ? 'Verifikasi OTP' : 'Password Baru',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                step == 1 ? 'Masukkan email akun Anda.' : step == 2 ? 'Masukkan 6 digit kode OTP.' : 'Buat sandi baru yang aman.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontFamily: 'Poppins'),
                              ),
                              const SizedBox(height: 24),
                              
                              if (step == 1)
                                TextFormField(
                                  controller: emailController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    hintText: 'Email',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                  validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                                ),

                              if (step == 2)
                                TextFormField(
                                  controller: otpController,
                                  style: const TextStyle(color: Colors.white, letterSpacing: 4),
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    hintText: '000000',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    counterText: "",
                                  ),
                                  validator: (v) => (v == null || v.length != 6) ? 'OTP harus 6 digit' : null,
                                ),

                              if (step == 3) ...[
                                TextFormField(
                                  controller: newPasswordController,
                                  obscureText: !showNewPassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    hintText: 'Password Baru',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    suffixIcon: IconButton(
                                      icon: Icon(showNewPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                                      onPressed: () => setDialogState(() => showNewPassword = !showNewPassword),
                                    )
                                  ),
                                  validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: !showConfirmPassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    hintText: 'Konfirmasi Password',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    suffixIcon: IconButton(
                                      icon: Icon(showConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
                                      onPressed: () => setDialogState(() => showConfirmPassword = !showConfirmPassword),
                                    )
                                  ),
                                  validator: (v) => (v != newPasswordController.text) ? 'Password tidak cocok' : null,
                                ),
                              ],

                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 5,
                                  ),
                                  onPressed: isLoading ? null : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setDialogState(() => isLoading = true);
                                    Map<String, dynamic> result = {};

                                    if (step == 1) {
                                      result = await apiService.sendOtp(email: emailController.text.trim());
                                      if (result['success'] == true) {
                                        setDialogState(() { step = 2; isLoading = false; });
                                        return;
                                      }
                                    } else if (step == 2) {
                                      result = await apiService.verifyOtp(email: emailController.text.trim(), otp: otpController.text.trim());
                                      if (result['success'] == true) {
                                        setDialogState(() { step = 3; isLoading = false; });
                                        return;
                                      }
                                    } else {
                                      result = await apiService.resetPassword(
                                        email: emailController.text.trim(),
                                        otp: otpController.text.trim(),
                                        password: newPasswordController.text,
                                        passwordConfirmation: confirmPasswordController.text,
                                      );
                                      if (result['success'] == true) {
                                        Navigator.of(context).pop();
                                        _showCustomAlert(result['message'] ?? 'Password berhasil direset!', isSuccess: true);
                                        return;
                                      }
                                    }
                                    setDialogState(() => isLoading = false);
                                    _showCustomAlert(result['message'] ?? 'Terjadi kesalahan.');
                                  },
                                  child: isLoading
                                      ? const _ModernLoading()
                                      : const Text('Lanjutkan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AnimatedBuilder(
        animation: _bgAnimController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF2E1065)],
                begin: _topAlignment.value,
                end: _bottomAlignment.value,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        // 3D/Vector Header Area
                        Center(
                          child: Container(
                            height: 180,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 40, spreadRadius: -10)
                              ]
                            ),
                            child: Image.asset(
                              "assets/images/logo.png",
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_pin, size: 100, color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Welcome Back!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 15,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 40),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildGlassTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Email wajib diisi';
                                  if (!val.contains('@')) return 'Format email tidak valid';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildGlassTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                isPasswordVisible: _isPasswordVisible,
                                onVisibilityToggle: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Password wajib diisi';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordPopup,
                            child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFA5B4FC), fontFamily: 'Poppins')),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  )
                                ]
                              ),
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 60, height: 24,
                                        child: Center(child: _ModernLoading()),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                                      ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontFamily: 'Poppins'),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pushReplacementNamed('/register'),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Color(0xFFA5B4FC),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ModernLoading extends StatefulWidget {
  final Color color;
  const _ModernLoading({this.color = Colors.white});
  @override
  State<_ModernLoading> createState() => _ModernLoadingState();
}

class _ModernLoadingState extends State<_ModernLoading> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final t = (_ctrl.value * 2 * math.pi) + (i * math.pi / 2);
            final offset = math.sin(t) * 4;
            final alpha = (math.sin(t) + 1) / 2 * 0.6 + 0.4;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Opacity(
                  opacity: alpha,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
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