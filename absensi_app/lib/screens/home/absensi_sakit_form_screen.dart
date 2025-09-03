// File: lib/screens/home/sakit_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // Import package untuk kompresi

class SakitFormScreen extends StatefulWidget {
  const SakitFormScreen({super.key});

  @override
  State<SakitFormScreen> createState() => _SakitFormScreenState();
}

class _SakitFormScreenState extends State<SakitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _catatanController = TextEditingController();
  File? _pickedFile;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  // Fungsi untuk mengompres file gambar
  Future<File?> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.path}_compressed.jpg', // Nama file sementara
      quality: 70, // Atur kualitas kompresi (0-100)
      minWidth: 1024,
      minHeight: 1024,
    );
    // Mengembalikan objek File dari XFile yang dihasilkan
    return result != null ? File(result.path) : null;
  }

  // Fungsi untuk mengambil foto dari kamera
  Future<void> _takePicture() async {
    final XFile? capturedImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, 
    );

    if (capturedImage != null) {
      final compressedFile = await _compressImage(File(capturedImage.path));
      if (compressedFile != null) {
        setState(() {
          _pickedFile = compressedFile;
        });
        _showSnackBar('Gambar berhasil dikompres dan dipilih.');
      } else {
        _showSnackBar('Gagal mengompres gambar.');
      }
    }
  }

  // Fungsi untuk memilih file dari galeri
  Future<void> _pickFile() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, 
    );

    if (pickedImage != null) {
      final compressedFile = await _compressImage(File(pickedImage.path));
      if (compressedFile != null) {
        setState(() {
          _pickedFile = compressedFile;
        });
        _showSnackBar('Gambar berhasil dikompres dan dipilih.');
      } else {
        _showSnackBar('Gagal mengompres gambar.');
      }
    }
  }

  // Helper function untuk menampilkan snackbar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Fungsi untuk mengirim form izin sakit
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _pickedFile != null) {
      setState(() {
        _isSubmitting = true;
      });

      final fileSizeInKB = await _pickedFile!.length() / 1024;
      print('Ukuran file yang akan dikirim: $fileSizeInKB KB');
      if (fileSizeInKB > 2048) {
         _showSnackBar('Ukuran file melebihi 2MB. Harap pilih gambar lain atau gunakan kamera.');
         setState(() {
            _isSubmitting = false;
         });
         return;
      }
      
      final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);

      final result = await absensiProvider.absenSakit(
        fileBukti: _pickedFile!,
        catatan: _catatanController.text,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        _showSnackBar(result['message'] ?? 'Berhasil mengajukan izin sakit.');
        if (result['success'] == true) {
          Navigator.pop(context);
        }
      }
    } else {
      _showSnackBar('Harap lengkapi semua field.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _catatanController,
                decoration: const InputDecoration(
                  labelText: 'Jenis Sakit (misal: Demam, Batuk)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sick_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Catatan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Bukti Dokumen (Surat Dokter / Screenshot Chat)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ambil Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Pilih File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_pickedFile != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_pickedFile!, fit: BoxFit.cover),
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('Belum ada bukti yang diunggah.'),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kirim Pengajuan',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
