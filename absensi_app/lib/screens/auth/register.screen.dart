import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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

  String _selectedEmploymentType = 'organik';
  String _selectedWorkLocation = 'office'; // ✅ TAMBAH

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

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
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
          workLocation: _selectedWorkLocation, // ✅ TAMBAH
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
      height: 56,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textAlign: TextAlign.start,
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
            borderSide: BorderSide(width: 1, color: Color(0xFF837E93)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(width: 1, color: Color(0xFF9F7BFF)),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(width: 1, color: Colors.red),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(width: 1.5, color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF755DC1),
            fontSize: 15,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(width: 1, color: Color(0xFF837E93)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(width: 1, color: Color(0xFF9F7BFF)),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF755DC1)),
          ),
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double horizontalPadding = 50.0;
    final contentWidth = screenWidth - (horizontalPadding * 2);
    final passwordFieldWidth = (contentWidth - 15) / 2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Image.asset(
                "assets/images/vector-2.png",
                width: screenWidth,
                height: screenWidth * 457 / 428,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: screenWidth,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text("Image not found", style: TextStyle(color: Colors.red)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    // Nama Lengkap
                    _buildStylishTextField(
                      controller: _nameController,
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap anda',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
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
                        if (value == null || value.isEmpty) return 'ID Karyawan tidak boleh kosong';
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
                        if (value == null || value.isEmpty) return 'Departemen tidak boleh kosong';
                        return null;
                      },
                    ),
                    const SizedBox(height: 17),

                    // Status Karyawan
                    _buildDropdown(
                      label: 'Status Karyawan',
                      icon: Icons.work,
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
                        if (value == null || value.isEmpty) return 'Status karyawan wajib dipilih';
                        return null;
                      },
                    ),
                    const SizedBox(height: 17),

                    // ✅ TAMBAH: Lokasi Kerja
                    _buildDropdown(
                      label: 'Lokasi Kerja',
                      icon: Icons.location_on,
                      value: _selectedWorkLocation,
                      items: const [
                        DropdownMenuItem(value: 'office', child: Text('Office')),
                        DropdownMenuItem(value: 'produksi', child: Text('Produksi')),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedWorkLocation = newValue!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Lokasi kerja wajib dipilih';
                        return null;
                      },
                    ),
                    const SizedBox(height: 17),

                    // Email
                    _buildStylishTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'Masukkan email anda',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                        if (!value.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 17),

                    // Password & Konfirmasi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStylishTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Create Password',
                          icon: Icons.lock,
                          obscureText: true,
                          width: passwordFieldWidth,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password tdk blh ksong';
                            if (value.length < 6) return 'Min 6 karakter';
                            return null;
                          },
                        ),
                        _buildStylishTextField(
                          controller: _passwordConfirmationController,
                          labelText: 'Konfirmasi',
                          hintText: 'Confirm Password',
                          icon: Icons.lock,
                          obscureText: true,
                          width: passwordFieldWidth,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Konfirmasi tdk blh ksong';
                            if (value != _passwordController.text) return 'Password tdk cocok';
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
                                      backgroundColor: const Color(0xFF9F7BFF),
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
                          'Have an account?',
                          style: TextStyle(
                            color: Color(0xFF837E93),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 2.5),
                        InkWell(
                          onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                          child: const Text(
                            'Log In',
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
                    const SizedBox(height: 20),
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