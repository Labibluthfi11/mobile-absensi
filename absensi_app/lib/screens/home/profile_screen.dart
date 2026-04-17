import 'package:universal_io/io.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../api/api.service.dart';

const Color kPrimaryColor = Color(0xFF4F46E5);
const Color kBackgroundColor = Color(0xFFF3F4F6);

// ----------------------------------------------------------------------
// MODERN UI COMPONENTS
// ----------------------------------------------------------------------

class ModernTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const ModernTextField({super.key, required this.label, required this.controller, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: TextFormField(
              controller: controller,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: Icon(icon, color: kPrimaryColor, size: 22),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class NonEditableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const NonEditableField({super.key, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: Colors.grey.shade500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
            final t = (_ctrl.value * 2 * math.pi) + (i * math.pi / 2);
            final offset = math.sin(t) * 4;
            final alpha = (math.sin(t) + 1) / 2 * 0.6 + 0.4;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Opacity(
                  opacity: alpha,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// MAIN SCREEN
// ----------------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idKaryawanController = TextEditingController();
  final TextEditingController _departemenController = TextEditingController();

  late Future<User?> _userProfileFuture;
  User? _user;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _fetchUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idKaryawanController.dispose();
    _departemenController.dispose();
    super.dispose();
  }

  Future<User?> _fetchUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
        setState(() => _imageFile = File(pickedFile.path));
        _showSnackBar('Foto berhasil dipilih! Jangan lupa klik Simpan.', isSuccess: true);
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil gambar. Pastikan Anda sudah memberikan izin.', isSuccess: false);
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;
    setState(() => _isSaving = true);

    try {
      await Future.delayed(const Duration(milliseconds: 600)); // Smooth loading transition
      
      final result = await _apiService.updateProfile(
        name: _nameController.text,
        email: _user!.email,
        idKaryawan: _idKaryawanController.text,
        departemen: _departemenController.text,
        employmentType: _user!.employmentType,
        profilePhoto: _imageFile,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        if (result['user'] != null && result['user'] is User) {
          final User updatedUser = result['user'] as User;
          Provider.of<AuthProvider>(context, listen: false).setUser(updatedUser);
          setState(() { _user = updatedUser; _imageFile = null; });
        }
        _showSnackBar(result['message'] ?? 'Profil berhasil diperbarui!', isSuccess: true);
      } else {
        _showSnackBar(result['message'] ?? 'Gagal memperbarui profil.', isSuccess: false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Koneksi gagal. Coba cek internet atau server.', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
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

  void _showLogoutDialog(AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Keluar Akun?', style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text('Apakah Anda yakin ingin keluar dari aplikasi? Anda harus login kembali nantinya.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    child: Text('Batal', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      authProvider.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    child: const Text('Ya, Keluar', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: FutureBuilder<User?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }

          if (snapshot.hasError || !snapshot.hasData || _user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Gagal memuat profil.', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () => setState(() => _userProfileFuture = _fetchUserProfile()), child: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Poppins', color: kPrimaryColor)))
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _ProfileHeaderDelegate(
                  user: _user!,
                  imageFile: _imageFile,
                  onPickImage: _pickImage,
                  maxExtent: 320,
                  minExtent: 100,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            _user!.employmentType.toUpperCase(),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: kPrimaryColor, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      ModernTextField(label: 'Nama Lengkap', controller: _nameController, icon: Icons.person_rounded),
                      ModernTextField(label: 'ID Karyawan', controller: _idKaryawanController, icon: Icons.badge_rounded),
                      ModernTextField(label: 'Departemen', controller: _departemenController, icon: Icons.apartment_rounded),
                      NonEditableField(label: 'Email Terdaftar', value: _user!.email, icon: Icons.email_rounded),
                      
                      const SizedBox(height: 16),

                      // Save Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(colors: [kPrimaryColor, Color(0xFF6366F1)]),
                          boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: _isSaving
                              ? const _ModernLoading()
                              : const Text('Simpan Perubahan', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Colors.black12, height: 1),
                      const SizedBox(height: 20),

                      // Logout Button
                      OutlinedButton.icon(
                        onPressed: () => _showLogoutDialog(authProvider),
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                        label: const Text('Keluar Akun', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.3), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// CUSTOM SLIVER HEADER (GOJEK/SHOPEE STYLE)
// ----------------------------------------------------------------------

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final User user;
  final File? imageFile;
  final VoidCallback onPickImage;
  final double _maxExtent;
  final double _minExtent;

  _ProfileHeaderDelegate({
    required this.user,
    required this.imageFile,
    required this.onPickImage,
    required double maxExtent,
    required double minExtent,
  })  : _maxExtent = maxExtent,
        _minExtent = minExtent;

  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return user != oldDelegate.user || imageFile != oldDelegate.imageFile;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double expandRatio = (1.0 - (shrinkOffset / (_maxExtent - _minExtent))).clamp(0.0, 1.0);
    
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        // Background Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        
        // App Bar Title (Fades in when scrolling up)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: 1.0 - expandRatio,
            child: const Center(
              child: Text(
                'Profil',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),

        // Expanded Profile Content
        Positioned(
          top: MediaQuery.of(context).padding.top + 40,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: expandRatio, // Fades out when scrolling up
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white,
                        backgroundImage: imageFile != null
                            ? FileImage(imageFile!)
                            : (user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty
                                ? NetworkImage(user.profilePhotoUrl!)
                                : null) as ImageProvider?,
                        child: (imageFile == null && (user.profilePhotoUrl == null || user.profilePhotoUrl!.isEmpty))
                            ? const Icon(Icons.person_rounded, size: 60, color: Colors.grey)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onPickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  user.idKaryawan,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom overlap curve to blend perfectly with background
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          child: Container(
            height: 30,
            decoration: const BoxDecoration(
              color: kBackgroundColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
          ),
        )
      ],
    );
  }
}