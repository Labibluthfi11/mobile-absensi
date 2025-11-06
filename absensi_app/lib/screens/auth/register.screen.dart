import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart'; // Pastikan path ini benar

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController = TextEditingController();
  final TextEditingController _idKaryawanController = TextEditingController();
  final TextEditingController _departemenController = TextEditingController();
  
  // Variabel untuk menyimpan pilihan status
  String _selectedEmploymentType = 'organik'; // Default ke Organik

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _idKaryawanController.dispose();
    _departemenController.dispose();
    super.dispose();
  }

  // FUNGSIONALITAS TETAP SAMA DENGAN KODE ASLI ANDA
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // Pastikan AuthProvider tersedia di atas widget ini
      final authProvider = Provider.of<AuthProvider>(context, listen: false); 

      try {
        await authProvider.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
          idKaryawan: _idKaryawanController.text,
          departemen: _departemenController.text,
          employmentType: _selectedEmploymentType,
        );

        if (authProvider.isAuthenticated) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi Berhasil!')),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.errorMessage ?? 'Registrasi gagal. Coba lagi.')),
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
  
  // WIDGET BARU UNTUK INPUT FIELD DENGAN STYLE BARU (BERDASARKAN SingUpScreen)
  Widget _buildStylishTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    double width = double.infinity,
  }) {
    return SizedBox(
      width: width,
      height: 56, // Tinggi yang disamakan dengan contoh
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textAlign: TextAlign.start, // Diubah ke start agar mirip style umumnya
        style: const TextStyle(
          color: Color(0xFF393939),
          fontSize: 13,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
        ),
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF755DC1)) : null,
          labelStyle: const TextStyle(
            color: Color(0xFF755DC1),
            fontSize: 15,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(
              width: 1,
              color: Color(0xFF837E93),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(
              width: 1,
              color: Color(0xFF9F7BFF),
            ),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(
              width: 1.5,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan lebar layar untuk penyesuaian (misalnya untuk Row password)
    final screenWidth = MediaQuery.of(context).size.width;
    // Padding horizontal di SingUpScreen adalah 50. Di sini akan disamakan
    const double horizontalPadding = 50.0;
    // Lebar yang tersisa untuk konten input setelah padding
    final contentWidth = screenWidth - (horizontalPadding * 2);
    // Lebar untuk masing-masing field Password/Confirm Password (dibagi 2 dan dikurangi spasi)
    final passwordFieldWidth = (contentWidth - 15) / 2; // 15 adalah jarak antar field

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView( // Menggunakan SingleChildScrollView agar semua field muat
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gambar Header (vector-2.png)
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Image.asset(
                "assets/images/vector-2.png", // Ganti dengan aset yang benar
                width: screenWidth, // Sesuaikan lebar gambar dengan lebar layar
                height: screenWidth * 457 / 428, // Proporsional dari ukuran asli
                fit: BoxFit.cover, // Gunakan cover agar mengisi area
                // Handle error jika gambar tidak ada (walaupun seharusnya sudah diatasi)
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: screenWidth,
                    color: Colors.grey[200],
                    child: const Center(child: Text("Image not found", style: TextStyle(color: Colors.red))),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 18),
            
            // 2. Konten Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  textDirection: TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul Sign up
                    const Text(
                      'Sign up',
                      style: TextStyle(
                        color: Color(0xFF755DC1),
                        fontSize: 27,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- FIELD INPUT ANDA DIMULAI DI SINI ---
                    
                    // Nama Lengkap
                    _buildStylishTextField(
                      controller: _nameController,
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap anda',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 17),

                    // ID Karyawan
                    _buildStylishTextField(
                      controller: _idKaryawanController,
                      labelText: 'ID Karyawan',
                      hintText: 'Contoh: AMB071107',
                      icon: Icons.badge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'ID Karyawan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 17),

                    // Departemen
                    _buildStylishTextField(
                      controller: _departemenController,
                      labelText: 'Departemen',
                      hintText: 'Masukkan nama departemen anda',
                      icon: Icons.business_center,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Departemen tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 17),
                    
                    // Status Karyawan (Dropdown)
                    // Menggunakan style dropdown yang lebih netral karena sulit meniru TextField style
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Karyawan',
                          style: TextStyle(
                            color: Color(0xFF755DC1),
                            fontSize: 15,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(width: 1, color: Color(0xFF837E93)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(width: 1, color: Color(0xFF9F7BFF)),
                            ),
                            prefixIcon: Icon(Icons.work, color: Color(0xFF755DC1)),
                          ),
                          value: _selectedEmploymentType,
                          items: const [
                            DropdownMenuItem(value: 'organik', child: Text('Karyawan Organik')),
                            DropdownMenuItem(value: 'freelance', child: Text('Freelance/Kontrak')),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedEmploymentType = newValue!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Status karyawan wajib dipilih';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),

                    // E-mail
                    _buildStylishTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'Masukkan email anda',
                      icon: Icons.email,
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
                    const SizedBox(height: 17),

                    // Password dan Konfirmasi Password (Dalam Row)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Password
                        _buildStylishTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Create Password',
                          icon: Icons.lock,
                          obscureText: true,
                          width: passwordFieldWidth,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password tdk blh ksong';
                            }
                            if (value.length < 6) {
                              return 'Min 6 karakter';
                            }
                            return null;
                          },
                        ),
                        
                        // Konfirmasi Password
                        _buildStylishTextField(
                          controller: _passwordConfirmationController,
                          labelText: 'Password',
                          hintText: 'Confirm Password',
                          icon: Icons.lock,
                          obscureText: true,
                          width: passwordFieldWidth,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi tdk blh ksong';
                            }
                            if (value != _passwordController.text) {
                              return 'Password tdk cocok';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 25),

                    // Tombol Register
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return authProvider.isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF9F7BFF)))
                            : ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(10)),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9F7BFF), // Warna ungu
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Create account',
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

                    // Pindah ke Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          ' have an account?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF837E93),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2.5),
                        InkWell(
                          onTap: () {
                            // Menggunakan Navigator.of(context).pushReplacementNamed('/login') sesuai kode asli Anda
                            Navigator.of(context).pushReplacementNamed('/login'); 
                          },
                          child: const Text(
                            'Log In ',
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
                    const SizedBox(height: 20), // Tambahkan sedikit ruang di bawah
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