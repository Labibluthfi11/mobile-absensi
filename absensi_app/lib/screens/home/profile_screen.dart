// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Pastikan path import ini benar di proyek Anda
import 'package:absensi_app/models/user_model.dart'; 
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/api/api.service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  // Inisialisasi ApiService
  final ApiService _apiService = ApiService(); 
  
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idKaryawanController = TextEditingController();
  final TextEditingController _departemenController = TextEditingController();
  // _emailController dan employmentType tidak perlu karena kita menggunakan _user lokal
  
  // Ubah tipe Future agar konsisten dengan getAuthenticatedUser di ApiService
  late Future<User?> _userProfileFuture;
  User? _user; // User lokal untuk menyimpan data yang ditampilkan/diedit
  bool _isSaving = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Panggil fungsi fetch terbaru
    _userProfileFuture = _fetchUserProfile();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idKaryawanController.dispose();
    _departemenController.dispose();
    _animationController.dispose(); 
    super.dispose();
  }

  /// Fungsi untuk mengambil data profil dari API (Menggunakan ApiService).
  Future<User?> _fetchUserProfile() async {
    // Cek apakah data sudah ada di AuthProvider saat ini
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _user = authProvider.user;
    } else {
      // Jika tidak ada di provider, ambil dari API
      final user = await _apiService.getAuthenticatedUser();
      if (user != null) {
        // Simpan ke provider jika berhasil diambil dari API
        authProvider.setUser(user);
        _user = user;
      }
    }

    if (_user != null) {
      // Set controller setelah data diterima
      _nameController.text = _user!.name;
      _idKaryawanController.text = _user!.idKaryawan;
      _departemenController.text = _user!.departemen;
    }

    return _user;
  }

  /// Fungsi untuk mengambil gambar dari galeri.
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error saat memilih gambar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengambil gambar. Pastikan Anda sudah memberikan izin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Fungsi untuk menyimpan perubahan profil ke API (Menggunakan ApiService).
  Future<void> _saveProfile() async {
    if (_user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data user tidak ditemukan.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await _apiService.updateProfile(
        name: _nameController.text,
        email: _user!.email, // Menggunakan email lama
        idKaryawan: _idKaryawanController.text,
        departemen: _departemenController.text,
        // ✅ KRITIS: Meneruskan employmentType yang tidak diedit
        employmentType: _user!.employmentType, 
        profilePhoto: _imageFile,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Update data user di provider dan di screen
          // ✅ Casting result['user'] sebagai User? karena ApiService mengembalikannya sebagai User
          if (result['user'] != null && result['user'] is User) {
            final User updatedUser = result['user'] as User;
            
            // Perbarui data di AuthProvider (Ini juga meng-update _user di memory dan SharedPreferences)
            Provider.of<AuthProvider>(context, listen: false).setUser(updatedUser);
            
            // Perbarui state lokal dan hapus file sementara
            setState(() {
              _user = updatedUser;
              _imageFile = null; // Hapus file lokal setelah berhasil diunggah
            });
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal memperbarui profil.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Koneksi gagal. Coba cek internet atau server.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // --- WIDGET HELPER ---
  
  Widget _buildFieldSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 16,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.only(bottom: 8),
          ),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Skeleton Avatar
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 24),
            // Skeleton Nama
            Container(
              width: 200,
              height: 28,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            // Skeleton Departemen
            Container(
              width: 150,
              height: 18,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 32),
            // Skeleton Fields
            _buildFieldSkeleton(),
            _buildFieldSkeleton(),
            _buildFieldSkeleton(),
            _buildFieldSkeleton(),
            _buildFieldSkeleton(),
            const SizedBox(height: 32),
            // Skeleton Tombol
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget kustom untuk field yang TIDAK bisa diedit
  Widget _buildNonEditableField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300)
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget kustom untuk field yang BISA diedit
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              fillColor: Colors.grey[50],
              filled: true,
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
  
  // Widget untuk animasi loading 'bouncing dots'
  Widget _buildBouncingDotsLoader({required Color dotColor}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Titik 1
            Transform.translate(
              offset: Offset(0, -10 * _animationController.value),
              child: _buildDot(dotColor),
            ),
            const SizedBox(width: 8),
            // Titik 2 dengan delay
            Transform.translate(
              offset: Offset(0, -10 * (1 - _animationController.value)),
              child: _buildDot(dotColor),
            ),
            const SizedBox(width: 8),
            // Titik 3
            Transform.translate(
              offset: Offset(0, -10 * _animationController.value),
              child: _buildDot(dotColor),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // --- BUILD METHOD UTAMA ---

  @override
  Widget build(BuildContext context) {
    // Gunakan listen: false di sini karena Anda hanya memanggil method logout
    final authProvider = Provider.of<AuthProvider>(context, listen: false); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      
      body: FutureBuilder<User?>( 
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: _buildProfileSkeleton(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Panggil ulang fungsi fetch yang sudah di-refactor
                          _userProfileFuture = _fetchUserProfile();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          // Pastikan _user sudah terisi
          if (snapshot.hasData && _user != null) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.blueGrey[50],
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              // Pengecekan profilePhotoUrl sudah benar
                              : (_user!.profilePhotoUrl != null && _user!.profilePhotoUrl!.isNotEmpty
                                  ? NetworkImage(_user!.profilePhotoUrl!)
                                  : null) as ImageProvider?,
                          child: (_imageFile == null && (_user!.profilePhotoUrl == null || _user!.profilePhotoUrl!.isEmpty))
                              ? Icon(
                                  Icons.account_circle,
                                  size: 160,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blueAccent,
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _user!.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user!.departemen,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '(${_user!.employmentType})', // Menampilkan employmentType
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // FIELDS YANG DAPAT DIEDIT
                    _buildEditableField(
                      label: 'Nama Karyawan',
                      controller: _nameController,
                    ),
                    _buildEditableField(
                      label: 'ID Karyawan',
                      controller: _idKaryawanController,
                    ),
                    _buildEditableField(
                      label: 'Departemen',
                      controller: _departemenController,
                    ),
                    // FIELD YANG TIDAK DAPAT DIEDIT (EMAIL)
                    _buildNonEditableField(
                      label: 'E-mail',
                      value: _user!.email,
                    ),
                    // FIELD YANG TIDAK DAPAT DIEDIT (TIPE PEKERJAAN)
                    _buildNonEditableField(
                      label: 'Tipe Pekerjaan',
                      value: _user!.employmentType, // Ditampilkan saja
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Panggil _saveProfile
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: _isSaving
                            ? _buildBouncingDotsLoader(dotColor: Colors.white)
                            : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          authProvider.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: const Text('Keluar', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('Tidak dapat memuat data. Mohon login kembali.'));
        },
      ),
    );
  }
}