// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Pastikan path import ini benar di proyek Anda
import 'package:absensi_app/models/user_model.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/api/api.service.dart';

// Definisi warna-warna modern
const Color _kPrimaryColor = Color(0xFF4F46E5); // Indigo
const Color _kSecondaryColor = Color(0xFF6366F1); // Light Indigo
const Color _kBackgroundColor = Color(0xFFF7F7F7); // Light Grey/Off-White
const Color _kCardColor = Colors.white;

// Custom Widget untuk Text Field ala Neumorphism/Modern
class ModernTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final IconData icon;

  const ModernTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.icon = Icons.edit_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(5, 5),
                ),
                const BoxShadow(
                  color: Colors.white,
                  blurRadius: 10,
                  offset: Offset(-5, -5),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _kPrimaryColor,
                    width: 2,
                  ),
                ),
                fillColor: _kCardColor,
                filled: true,
                prefixIcon: Icon(
                  icon,
                  color: _kPrimaryColor.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Widget untuk Field Non-Editable ala Modern
class NonEditableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const NonEditableField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200.withOpacity(0.5),
                  blurRadius: 5,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idKaryawanController = TextEditingController();
  final TextEditingController _departemenController = TextEditingController();

  late Future<User?> _userProfileFuture;
  User? _user;
  bool _isSaving = false;

  // Animasi untuk Skeleton Loader dan Tombol Loading
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _shimmerColorAnimation;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _fetchUserProfile();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _shimmerColorAnimation = ColorTween(
      begin: _kPrimaryColor.withOpacity(0.3),
      end: _kPrimaryColor.withOpacity(0.8),
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idKaryawanController.dispose();
    _departemenController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<User?> _fetchUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // ... (Logika fetch user tetap sama)
    if (authProvider.user != null) {
      _user = authProvider.user;
    } else {
      final user = await _apiService.getAuthenticatedUser();
      if (user != null) {
        authProvider.setUser(user);
        _user = user;
      }
    }

    if (_user != null) {
      _nameController.text = _user!.name;
      _idKaryawanController.text = _user!.idKaryawan;
      _departemenController.text = _user!.departemen;
    }

    return _user;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        _showSnackBar('Foto berhasil dipilih! Jangan lupa simpan perubahan.', isError: false);
      }
    } catch (e) {
      debugPrint('Error saat memilih gambar: $e');
      if (mounted) {
        _showSnackBar('Gagal mengambil gambar. Pastikan Anda sudah memberikan izin.', isError: true);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) {
      if (mounted) {
        _showSnackBar('Data user tidak ditemukan.', isError: true);
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Menunda sebentar untuk efek loading premium
      await Future.delayed(const Duration(milliseconds: 500));
      
      final result = await _apiService.updateProfile(
        name: _nameController.text,
        email: _user!.email,
        idKaryawan: _idKaryawanController.text,
        departemen: _departemenController.text,
        employmentType: _user!.employmentType,
        profilePhoto: _imageFile,
      );

      if (mounted) {
        if (result['success'] == true) {
          if (result['user'] != null && result['user'] is User) {
            final User updatedUser = result['user'] as User;

            Provider.of<AuthProvider>(context, listen: false).setUser(updatedUser);

            setState(() {
              _user = updatedUser;
              _imageFile = null; // Reset file lokal setelah berhasil di-upload
            });
          }

          _showSnackBar(result['message'] ?? 'Profil berhasil diperbarui! 🎉', isError: false);
        } else {
          _showSnackBar(result['message'] ?? 'Gagal memperbarui profil. 😔', isError: true);
        }
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        _showSnackBar('Koneksi gagal. Coba cek internet atau server.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE53E3E) : const Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 10,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- WIDGET HELPER ---

  // Custom Skeleton Widget untuk kesan loading yang lebih profesional
  Widget _buildFieldSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: 250,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: 180,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            _buildFieldSkeleton(),
            _buildFieldSkeleton(),
            _buildFieldSkeleton(),
            _buildFieldSkeleton(),
            _buildFieldSkeleton(),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _kPrimaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Tombol dengan efek Shimmer saat Loading (Ganti BouncingDots)
  Widget _buildShimmerButtonContent() {
    return AnimatedBuilder(
      animation: _shimmerColorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                _shimmerColorAnimation.value!.withOpacity(0.8),
                _shimmerColorAnimation.value!,
                _shimmerColorAnimation.value!.withOpacity(0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              'Menyimpan...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Profil Karyawan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kBackgroundColor,
                _kBackgroundColor.withOpacity(0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: FutureBuilder<User?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: _buildProfileSkeleton(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            // ... (Bagian error tetap bagus)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_off, // Icon lebih elegan
                        size: 64,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Gagal Memuat Data',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pastikan koneksi internet Anda stabil dan coba lagi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _userProfileFuture = _fetchUserProfile();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Muat Ulang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_user != null) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 120, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- PROFILE PHOTO SECTION ---
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _kPrimaryColor.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 5,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 80, // Ukuran diperbesar sedikit
                            backgroundColor: _kCardColor,
                            child: CircleAvatar(
                              radius: 76,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_user!.profilePhotoUrl != null && _user!.profilePhotoUrl!.isNotEmpty
                                          ? NetworkImage(_user!.profilePhotoUrl!)
                                          : null) as ImageProvider?,
                              child: (_imageFile == null && (_user!.profilePhotoUrl == null || _user!.profilePhotoUrl!.isEmpty))
                                  ? Icon(
                                      Icons.person_pin_circle_outlined, // Icon lebih modern
                                      size: 152,
                                      color: Colors.grey[300],
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_kPrimaryColor, _kSecondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: _kCardColor, width: 3), // Border putih elegan
                                boxShadow: [
                                  BoxShadow(
                                    color: _kPrimaryColor.withOpacity(0.5),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _user!.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30, // Font lebih besar
                        fontWeight: FontWeight.w900, // Lebih tebal
                        color: Colors.black87,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: _kPrimaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _user!.departemen,
                        style: const TextStyle(
                          fontSize: 18,
                          color: _kPrimaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _user!.employmentType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- INPUT FIELDS SECTION ---
                    ModernTextField(
                      label: 'Nama Karyawan',
                      controller: _nameController,
                      icon: Icons.person_outline,
                    ),
                    ModernTextField(
                      label: 'ID Karyawan',
                      controller: _idKaryawanController,
                      icon: Icons.badge_outlined,
                    ),
                    ModernTextField(
                      label: 'Departemen',
                      controller: _departemenController,
                      icon: Icons.apartment_outlined,
                    ),
                    NonEditableField(
                      label: 'E-mail (Tidak Dapat Diubah)',
                      value: _user!.email,
                      icon: Icons.email_outlined,
                    ),
                    NonEditableField(
                      label: 'Tipe Pekerjaan (Tidak Dapat Diubah)',
                      value: _user!.employmentType,
                      icon: Icons.work_outline,
                    ),
                    const SizedBox(height: 40),

                    // --- SAVE BUTTON ---
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimaryColor.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _isSaving
                          ? _buildShimmerButtonContent() // Tampilkan shimmer loading
                          : ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero, // Padding 0 agar bisa diatur oleh Container gradien
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                backgroundColor: Colors.transparent, // Transparan agar gradien terlihat
                                foregroundColor: Colors.white,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_kPrimaryColor, _kSecondaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(minHeight: 58),
                                  alignment: Alignment.center,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save_outlined, size: 20),
                                      SizedBox(width: 12),
                                      Text(
                                        'Simpan Perubahan',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- LOGOUT BUTTON ---
                    Container(
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade100.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          authProvider.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kCardColor,
                          foregroundColor: const Color(0xFFE53E3E),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.red.shade200,
                              width: 1.5,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Keluar Akun',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Fallback jika tidak ada data dan tidak ada error (walaupun seharusnya sudah ditangani)
          return const Center(child: Text('Data profil tidak tersedia.'));
        },
      ),
    );
  }
}