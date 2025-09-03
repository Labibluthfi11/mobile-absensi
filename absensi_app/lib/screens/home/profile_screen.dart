import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:absensi_app/models/user_model.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:absensi_app/core/constants/api_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idKaryawanController = TextEditingController();
  final TextEditingController _departemenController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  late Future<User> _userProfileFuture;
  User? _user;
  bool _isSaving = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userProfileFuture = _fetchUserProfile(authProvider.token!);

    // Inisialisasi AnimationController untuk animasi loading
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(); // Mengulang animasi secara terus menerus
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idKaryawanController.dispose();
    _departemenController.dispose();
    _emailController.dispose();
    _animationController.dispose(); // Pastikan controller di-dispose
    super.dispose();
  }

  /// Fungsi untuk mengambil data profil dari API.
  Future<User> _fetchUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.BASE_URL}/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _user = User.fromJson(userData);

        _nameController.text = _user!.name;
        _idKaryawanController.text = _user!.idKaryawan;
        _departemenController.text = _user!.departemen;
        _emailController.text = _user!.email;

        return _user!;
      } else {
        throw Exception('Gagal mengambil data profil. Status: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Gagal terhubung ke server. Pastikan server berjalan dan alamat IP benar. Error: ${e.message}');
    } on SocketException catch (e) {
      throw Exception('Koneksi internet tidak tersedia atau server tidak dapat dijangkau. Error: ${e.message}');
    } catch (e) {
      throw Exception('Terjadi kesalahan tidak terduga: $e');
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil gambar. Pastikan Anda sudah memberikan izin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Fungsi untuk menyimpan perubahan profil ke API.
  Future<void> _saveProfile(String token) async {
    setState(() {
      _isSaving = true;
    });

    final uri = Uri.parse('${ApiConstants.BASE_URL}/user/profile');
    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['_method'] = 'PUT';
    request.fields['name'] = _nameController.text;
    request.fields['id_karyawan'] = _idKaryawanController.text;
    request.fields['departemen'] = _departemenController.text;

    if (_imageFile != null) {
      final mimeTypeData = lookupMimeType(_imageFile!.path)?.split('/');
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_photo',
          _imageFile!.path,
          contentType: mimeTypeData != null && mimeTypeData.length == 2
              ? MediaType(mimeTypeData[0], mimeTypeData[1])
              : null,
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['user'] != null) {
          _user = User.fromJson(responseData['user']);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        
      } else {
        String message = 'Gagal memperbarui profil. Status: ${response.statusCode}';
        if (responseData.containsKey('errors')) {
          message = responseData['errors'].values.first[0];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koneksi gagal. Pastikan server berjalan dan alamat IP benar.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      
      body: FutureBuilder<User>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              // Menggunakan animasi loading tiga titik saat memuat data profil
              child: _buildBouncingDotsLoader(dotColor: Colors.blueAccent),
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
                          _userProfileFuture = _fetchUserProfile(authProvider.token!);
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

          if (snapshot.hasData) {
            _user = snapshot.data;
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
                              : (_user?.profilePhotoUrl != null && _user!.profilePhotoUrl!.isNotEmpty
                                  ? NetworkImage(_user!.profilePhotoUrl!)
                                  : null) as ImageProvider?,
                          child: (_imageFile == null && (_user?.profilePhotoUrl == null || _user!.profilePhotoUrl!.isEmpty))
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
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
                    const SizedBox(height: 32),
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
                    _buildNonEditableField(
                      label: 'E-mail',
                      value: _user!.email,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveProfile(authProvider.token!),
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
