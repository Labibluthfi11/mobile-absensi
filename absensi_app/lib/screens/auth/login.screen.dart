import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/auth_provider.dart';
 // Nanti akan dibuat, pastikan path benar

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      try {
        await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // Jika berhasil login, Navigator akan otomatis mengarahkan
        // ke HomeScreen karena kita menggunakan Consumer di main.dart
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        String errorMessage = authProvider.errorMessage ?? 'Terjadi kesalahan tidak dikenal.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna di sini untuk kemudahan akses dan konsistensi UI
    final Color dustyLatte100 = const Color(0xFFF4F0EB); // Background halaman
    final Color softIndigo600 = const Color(0xFF4F46E5); // Untuk tombol, checkbox, text link

    return Scaffold(
      backgroundColor: dustyLatte100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.85, // max-w-md
                constraints: BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white // bg-white
                      : Colors.grey[800], // dark:bg-gray-800
                  borderRadius: BorderRadius.circular(24), // rounded-2xl
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade200 // border-gray-200
                        : Colors.grey.shade700, // dark:border-gray-700
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15), // shadow-xl (sedikit diubah untuk Flutter)
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: Offset(0, 8), // mirip shadow-xl
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Ansel
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Image.asset(
                          'assets/images/logo.png', // Pastikan logo ada di assets/images/
                          height: 80, // h-20
                        ),
                      ),
                      Text(
                        'Selamat Datang',
                        style: TextStyle(
                          fontSize: 28, // text-3xl
                          fontWeight: FontWeight.bold, // font-bold
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.grey.shade800 // text-gray-800
                              : Colors.white, // dark:text-white
                          letterSpacing: -0.5, // tracking-tight
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan masuk untuk melanjutkan',
                        style: TextStyle(
                          fontSize: 16, // text-base
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.grey.shade600 // text-gray-600
                              : Colors.grey.shade400, // dark:text-gray-400
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Masukkan email Anda',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!value.contains('@')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Masukkan password Anda',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (value.length < 8) {
                            return 'Password minimal 8 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: false, // Implementasi remember me nanti
                                onChanged: (bool? newValue) {
                                  // setState(() { _rememberMe = newValue!; });
                                },
                                activeColor: softIndigo600, // text-softIndigo-600
                                checkColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.black, // Checkmark color
                              ),
                              Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness == Brightness.light
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Fitur Lupa Password belum diimplementasikan.')),
                              );
                            },
                            child: Text(
                              'Lupa Password?',
                              style: TextStyle(
                                fontSize: 14,
                                color: softIndigo600, // text-softIndigo-600
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity, // w-full
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _login,
                          child: authProvider.isLoading
                              ? CircularProgressIndicator(
                                  // <<< INI BAGIAN YANG DIPERBAIKI >>>
                                  color: Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.white,
                                )
                              : Text(
                                  'Log In',
                                  style: TextStyle(
                                    color: Colors.black, // text-black
                                    fontWeight: FontWeight.w600, // font-semibold
                                    fontSize: 18, // text-lg
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Belum punya akun? Register
                      Text(
                        'Belum punya akun?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fitur Register belum diimplementasikan.')),
                          );
                        },
                        child: Text(
                          'Daftar sekarang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500, // font-medium
                            color: softIndigo600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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