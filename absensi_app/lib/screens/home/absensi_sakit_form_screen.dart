// File: lib/screens/home/absensi_sakit_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
// Jika kamu menggunakan provider di sini, pastikan import ini benar.
// import 'package:absensi_app/providers/absensi_provider.dart'; 


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
  String _tipePengajuan = 'sakit'; // Default: sakit

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<File?> _compressImage(File file) async {
    // Pastikan path dan file compress sudah benar
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      '${file.path}_compressed.jpg',
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );
    return result != null ? File(result.path) : null;
  }

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

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Menampilkan opsi kamera/galeri
  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto (Kamera)'),
              onTap: () {
                Navigator.pop(ctx);
                _takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _pickedFile != null) {
      setState(() {
        _isSubmitting = true;
      });

      final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);
      Map<String, dynamic> result;

      if (_tipePengajuan == 'sakit') {
        result = await absensiProvider.absenSakit(
          fileBukti: _pickedFile!,
          catatan: _catatanController.text,
        );
      } else {
        result = await absensiProvider.absenIzin(
          fileBukti: _pickedFile!,
          catatan: _catatanController.text,
        );
      }
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        _showSnackBar(result['message'] ?? 'Berhasil mengajukan pengajuan.');
        if (result['success'] == true) {
          // Setelah sukses, kembali ke halaman Home
          // Karena SakitFormScreen sekarang adalah salah satu tab,
          // kita tidak perlu pop, user bisa pindah tab.
        }
      }
    } else {
      _showSnackBar('Harap lengkapi semua field dan unggah bukti.');
    }
  }
  
  // Widget baru untuk tombol Izin/Sakit
  Widget _buildChoiceButton(String label, String value) {
    bool isSelected = _tipePengajuan == value;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _tipePengajuan = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.red : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isSelected ? BorderSide.none : const BorderSide(color: Colors.grey),
        ),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // Widget baru untuk tombol Kirim
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366), // Warna Biru Gelap
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Kirim Pengajuan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Karena ini adalah salah satu konten dari BottomNavigationBar, 
    // kita tidak butuh Scaffold lagi di sini. Cukup SingleChildScrollView.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: Container(
          // Card Box UI
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER CARD
                const Center(
                  child: Text(
                    'Pengajuan Ketidakhadiran',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Center(
                  child: Text(
                    'Isi form untuk mengajukan Izin atau Sakit.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 25),

                // PILIHAN JENIS IZIN/SAKIT
                const Text(
                  'Jenis Pengajuan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildChoiceButton('Sakit', 'sakit')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildChoiceButton('Izin', 'izin')),
                  ],
                ),
                const SizedBox(height: 20),

                // ALASAN / CATATAN
                TextFormField(
                  controller: _catatanController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Catatan/Alasan',
                    hintText:
                        'Masukkan Alasan (${_tipePengajuan == 'sakit' ? 'misal: Demam tinggi, lampirkan surat dokter' : 'misal: Keperluan keluarga yang mendesak'})',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Catatan tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // BUKTI DOKUMEN
                const Text(
                  'Unggah Bukti Dokumen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _showPickerOptions,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      hintText: _pickedFile == null ? 'Pilih File (Foto/Dokumen)' : _pickedFile!.path.split('/').last,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.upload_file),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                    child: Text(
                      _pickedFile == null ? 'Pilih File' : _pickedFile!.path.split('/').last,
                      style: TextStyle(
                        color: _pickedFile == null ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // PREVIEW GAMBAR
                if (_pickedFile != null)
                  Center(
                    child: Container(
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
                    ),
                  )
                else
                  const Center(child: Text('Belum ada bukti yang diunggah.')),
                
                const SizedBox(height: 30),

                // TOMBOL KIRIM
                _buildSubmitButton(),
                
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Pastikan Anda mengisi semua data di atas dengan benar.\nTerima kasih.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}