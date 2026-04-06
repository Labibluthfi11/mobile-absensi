import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../api/api.service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (authProvider.isAuthenticated) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Berhasil!')),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.errorMessage ?? 'Login gagal. Coba lagi.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Terjadi kesalahan tidak terduga.')),
        );
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
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

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {

            Widget stepContent() {
              if (step == 1) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masukkan email akun Anda. Kami akan mengirimkan kode OTP.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Color(0xFF755DC1), fontFamily: 'Poppins'),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Color(0xFF837E93)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Color(0xFF9F7BFF)),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                        if (!v.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                  ],
                );
              }

              if (step == 2) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kode OTP telah dikirim ke ${emailController.text}. Masukkan kode 6 digit.',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Kode OTP',
                        labelStyle: TextStyle(color: Color(0xFF755DC1), fontFamily: 'Poppins'),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Color(0xFF837E93)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Color(0xFF9F7BFF)),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'OTP tidak boleh kosong';
                        if (v.length != 6) return 'OTP harus 6 digit';
                        return null;
                      },
                    ),
                  ],
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan password baru Anda.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: !showNewPassword,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      labelStyle: const TextStyle(color: Color(0xFF755DC1), fontFamily: 'Poppins'),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(color: Color(0xFF837E93)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(color: Color(0xFF9F7BFF)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showNewPassword ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF755DC1),
                        ),
                        onPressed: () => setDialogState(() => showNewPassword = !showNewPassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                      if (v.length < 8) return 'Password minimal 8 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      labelStyle: const TextStyle(color: Color(0xFF755DC1), fontFamily: 'Poppins'),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(color: Color(0xFF837E93)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(color: Color(0xFF9F7BFF)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF755DC1),
                        ),
                        onPressed: () => setDialogState(() => showConfirmPassword = !showConfirmPassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                      if (v != newPasswordController.text) return 'Password tidak sama';
                      return null;
                    },
                  ),
                ],
              );
            }

            String titleText() {
              if (step == 1) return 'Lupa Password';
              if (step == 2) return 'Verifikasi OTP';
              return 'Password Baru';
            }

            String buttonText() {
              if (step == 1) return 'Kirim OTP';
              if (step == 2) return 'Verifikasi';
              return 'Reset Password';
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text(
                titleText(),
                style: const TextStyle(
                  color: Color(0xFF755DC1),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Form(
                key: formKey,
                child: stepContent(),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9F7BFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isLoading = true);

                          Map<String, dynamic> result = {};

                          if (step == 1) {
                            result = await apiService.sendOtp(
                              email: emailController.text.trim(),
                            );
                            if (result['success'] == true) {
                              setDialogState(() { step = 2; isLoading = false; });
                              return;
                            }
                          } else if (step == 2) {
                            result = await apiService.verifyOtp(
                              email: emailController.text.trim(),
                              otp: otpController.text.trim(),
                            );
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
                              if (!context.mounted) return;
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Password berhasil direset!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              return;
                            }
                          }

                          setDialogState(() => isLoading = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Terjadi kesalahan.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(buttonText(), style: const TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 15),
              child: Image.asset(
                "assets/images/vector-1.png",
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.45,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Log In',
                      style: TextStyle(
                        color: Color(0xFF755DC1),
                        fontSize: 27,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        color: Color(0xFF393939),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: Color(0xFF755DC1),
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(width: 1, color: Color(0xFF837E93)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(width: 1, color: Color(0xFF9F7BFF)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                        if (!value.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Password Field + Show/Hide
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(
                        color: Color(0xFF393939),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(
                          color: Color(0xFF755DC1),
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(width: 1, color: Color(0xFF837E93)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(width: 1, color: Color(0xFF9F7BFF)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF755DC1),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),

                    // Tombol Sign In
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return authProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(10)),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9F7BFF),
                                    ),
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                      },
                    ),
                    const SizedBox(height: 15),

                    // Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Don\'t have an account?',
                          style: TextStyle(
                            color: Color(0xFF837E93),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2.5),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/register'),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF755DC1),
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Forgot Password
                    Center(
                      child: GestureDetector(
                        onTap: _showForgotPasswordDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF755DC1),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}