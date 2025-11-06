import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // Menggunakan controller yang sudah ada dari kode kedua
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController(); 
  // Mengganti _passController menjadi _passwordController agar sesuai dengan kode kedua
  // final TextEditingController _passController = TextEditingController(); 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi login Anda yang dipertahankan
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

  @override
  Widget build(BuildContext context) {
    // UI yang baru (mengikuti style kode pertama)
    return Scaffold(
      backgroundColor: Colors.white, // Background putih seperti kode pertama
      body: SingleChildScrollView( // Tambahkan SingleChildScrollView agar tidak overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Awal (mengikuti kode pertama)
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 15),
              child: Image.asset(
                "assets/images/vector-1.png", // Pastikan path ini benar di project Anda
                // Sesuaikan lebar dan tinggi agar responsif
                width: MediaQuery.of(context).size.width, 
                height: MediaQuery.of(context).size.height * 0.45,
                fit: BoxFit.contain, // Ubah BoxFit agar gambar terlihat utuh
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Form( // Pertahankan Form dari kode kedua
                key: _formKey,
                child: Column(
                  textDirection: TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul 'Log In' (mengikuti kode pertama)
                    const Text(
                      'Log In',
                      style: TextStyle(
                        color: Color(0xFF755DC1), // Warna ungu
                        fontSize: 27,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(
                      height: 50,
                    ),

                    // --- Bidang Email ---
                    TextFormField( // Menggunakan TextFormField dari kode kedua untuk validasi
                      controller: _emailController,
                      textAlign: TextAlign.start, // Diubah menjadi start agar lebih umum
                      style: const TextStyle(
                        color: Color(0xFF393939),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                      // Dekorasi dari kode pertama
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
                          borderSide: BorderSide(
                            width: 1,
                            color: Color(0xFF837E93),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(
                            width: 1,
                            color: Color(0xFF9F7BFF),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress, // Pertahankan dari kode kedua
                      validator: (value) { // Pertahankan validator dari kode kedua
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!value.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 30,
                    ),

                    // --- Bidang Password ---
                    TextFormField( // Menggunakan TextFormField dari kode kedua untuk validasi
                      controller: _passwordController,
                      textAlign: TextAlign.start, // Diubah menjadi start
                      obscureText: true, // Pertahankan dari kode kedua
                      style: const TextStyle(
                        color: Color(0xFF393939),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                      // Dekorasi dari kode pertama
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: Color(0xFF755DC1),
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(
                            width: 1,
                            color: Color(0xFF837E93),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(
                            width: 1,
                            color: Color(0xFF9F7BFF),
                          ),
                        ),
                      ),
                      validator: (value) { // Pertahankan validator dari kode kedua
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 25,
                    ),

                    // --- Tombol Sign In (Login) ---
                    Consumer<AuthProvider>( // Pertahankan Consumer/fungsi login dari kode kedua
                      builder: (context, authProvider, child) {
                        return authProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ClipRRect( // Style tombol dari kode pertama
                                borderRadius: const BorderRadius.all(Radius.circular(10)),
                                child: SizedBox(
                                  width: double.infinity, // Dibuat penuh
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _login, // Menggunakan fungsi login Anda
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9F7BFF), // Warna ungu
                                    ),
                                    child: const Text(
                                      'Sign In', // Ubah teks tombol jika perlu, menggunakan 'Sign In' untuk meniru kode pertama
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
                    
                    const SizedBox(
                      height: 15,
                    ),

                    // --- "Don't have an account?" / Pindah ke Register ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Pusatkan row
                      children: [
                        const Text(
                          'Don’t have an account?',
                          style: TextStyle(
                            color: Color(0xFF837E93),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(
                          width: 2.5,
                        ),
                        // Menggunakan TextButton untuk 'Sign Up' 
                        TextButton(
                          onPressed: () {
                            // Mengganti navigasi PageController dengan navigasi named route Anda
                            Navigator.of(context).pushReplacementNamed('/register'); 
                          },
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
                    
                    const SizedBox(
                      height: 15,
                    ),

                    // --- Forget Password? ---
                    const Center( // Pusatkan Text
                      child: Text(
                        'Forget Password?',
                        style: TextStyle(
                          color: Color(0xFF755DC1),
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50), // Tambahkan ruang bawah
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