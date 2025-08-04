import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // File untuk menyimpan gambar profil yang dipilih.
  // Mulai dengan null, yang akan diganti dengan file saat gambar dipilih.
  File? _imageFile;
  
  // Controller untuk mengelola input teks nama pengguna.
  final TextEditingController _nameController = TextEditingController();

  // Variabel untuk menyimpan email pengguna.
  // Ini biasanya diisi otomatis dari data login.
  // Saya menggunakan contoh email di sini.
  final String _userEmail = 'pengguna@contoh.com';

  // State untuk menunjukkan apakah aplikasi sedang memuat (misalnya saat menyimpan).
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Di sini Anda bisa mengisi data pengguna secara otomatis
    // dari database atau provider.
    // Untuk contoh ini, saya mengisi dengan data dummy.
    _nameController.text = 'Nama Pengguna';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil gambar dari galeri atau kamera.
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Fungsi untuk menyimpan perubahan profil.
  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    // Simulasikan proses menyimpan data ke backend.
    await Future.delayed(const Duration(seconds: 2));
    
    // Di sini Anda akan mengimplementasikan logika untuk:
    // 1. Mengunggah _imageFile ke layanan penyimpanan (misalnya Firebase Storage).
    // 2. Memperbarui nama pengguna di database.
    // 3. Menampilkan pesan sukses.
    print('Nama: ${_nameController.text}');
    print('Email: $_userEmail');
    if (_imageFile != null) {
      print('Mengunggah file gambar: ${_imageFile!.path}');
    }

    setState(() {
      _isLoading = false;
    });

    // Tampilkan pesan konfirmasi
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Widget untuk foto profil dan tombol edit
            Stack(
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null 
                    ? FileImage(_imageFile!) as ImageProvider
                    : const NetworkImage('https://placehold.co/160x160/png') as ImageProvider,
                  child: _imageFile == null
                      ? const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.grey,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: const CircleBorder(),
                    ),
                    onPressed: () {
                      // Tampilkan dialog pilihan kamera atau galeri
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Galeri'),
                                  onTap: () {
                                    _pickImage(ImageSource.gallery);
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Kamera'),
                                  onTap: () {
                                    _pickImage(ImageSource.camera);
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Widget untuk nama pengguna
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Pengguna',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Widget untuk email (read-only)
            TextField(
              readOnly: true,
              controller: TextEditingController(text: _userEmail),
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol simpan
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Simpan Perubahan'),
                  ),
          ],
        ),
      ),
    );
  }
}