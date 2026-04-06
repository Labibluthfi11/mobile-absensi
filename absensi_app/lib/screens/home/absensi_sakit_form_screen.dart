// lib/pages/sakit_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// --- Definisi Warna Korporat ---
const Color kPrimaryColor = Color(0xFF152C5C); // Dark Corporate Blue
const Color kAccentColor = Color(0xFF3B82F6); // Standard Bright Blue
const Color kBackgroundColor = Color(0xFFF7F9FB); // Very Light Background

class SakitFormScreen extends StatefulWidget {
  /// Jika [resubmitId] diberikan, screen akan berjalan dalam mode "Ajukan Ulang".
  /// [existingAbsensi] opsional — dipakai untuk menampilkan file lama / catatan lama.
  final int? resubmitId;
  final Absensi? existingAbsensi;

  const SakitFormScreen({super.key, this.resubmitId, this.existingAbsensi});

  @override
  State<SakitFormScreen> createState() => _SakitFormScreenState();
}

class _SakitFormScreenState extends State<SakitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _catatanPanggilanController = TextEditingController();
  File? _pickedFile;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  String _tipePengajuan = 'sakit'; // Default: sakit
  String _jenisCuti = 'cuti_tahunan'; // default

  @override
  void initState() {
    super.initState();
    // Jika ada existingAbsensi, prefill catatan & tipe
    if (widget.existingAbsensi != null) {
      _tipePengajuan = (widget.existingAbsensi!.tipe ?? 'sakit').toLowerCase();
      
      // Prefill alasan utama
      _catatanController.text = widget.existingAbsensi!.keterangan ??
          widget.existingAbsensi!.keterangan ??
          '';
      
      // Prefill catatan panggilan (untuk izin)
      if (_tipePengajuan == 'izin') {
        _catatanPanggilanController.text = widget.existingAbsensi!.catatanAdmin ?? '';
      }
      
      debugPrint('🔄 [FORM] Prefilled data - Tipe: $_tipePengajuan, Catatan: ${_catatanController.text}');
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _catatanPanggilanController.dispose();
    super.dispose();
  }

  Future<File?> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );
      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('❌ Error compressing image: $e');
      return null;
    }
  }

  Future<void> _takePicture() async {
    Navigator.pop(context);
    try {
      final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (capturedImage != null) {
        final compressedFile = await _compressImage(File(capturedImage.path));
        if (mounted) {
          setState(() {
            _pickedFile = compressedFile;
          });
          _showSnackBar(
            compressedFile != null 
              ? 'Foto berhasil diunggah.' 
              : 'Gagal mengompres gambar.'
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error taking picture: $e');
      _showSnackBar('Gagal mengambil foto.');
    }
  }

  Future<void> _pickFile() async {
    Navigator.pop(context);
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        final compressedFile = await _compressImage(File(pickedImage.path));
        if (mounted) {
          setState(() {
            _pickedFile = compressedFile;
          });
          _showSnackBar(
            compressedFile != null 
              ? 'Gambar berhasil diunggah.' 
              : 'Gagal mengompres gambar.'
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error picking file: $e');
      _showSnackBar('Gagal memilih file.');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: kPrimaryColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Pilih Bukti',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const Divider(height: 20),
              _buildModalListTile(
                icon: Icons.camera_alt_outlined,
                title: 'Ambil Foto Langsung',
                onTap: _takePicture,
              ),
              _buildModalListTile(
                icon: Icons.photo_library_outlined,
                title: 'Pilih dari Galeri',
                onTap: _pickFile,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: kAccentColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  // ✅ FIXED: Submit form dengan proper debugging dan error handling
  Future<void> _submitForm() async {
    final isResubmit = widget.resubmitId != null;
    
    debugPrint('📝 [FORM] Submit started - isResubmit: $isResubmit, tipe: $_tipePengajuan');

    // Validasi form
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Periksa kembali form Anda.');
      return;
    }

    // Validasi khusus untuk izin
    final isIzinValid = _tipePengajuan == 'sakit' ||
    _tipePengajuan == 'cuti' ||
    (_tipePengajuan == 'izin' && _catatanPanggilanController.text.isNotEmpty);

    if (!isIzinValid) {
      _showSnackBar('Harap lengkapi Catatan Kepentingan/Panggilan untuk Izin.');
      return;
    }

    // Validasi file wajib untuk resubmit
    if (isResubmit && _pickedFile == null) {
      _showSnackBar('Harap unggah bukti terbaru untuk ajukan ulang.');
      return;
    }

    // Validasi file untuk pengajuan baru
    if (!isResubmit && _pickedFile == null) {
      _showSnackBar('Harap unggah bukti dokumen.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);
    Map<String, dynamic> result = {'success': false, 'message': 'Tidak ada aksi.'};

    try {
      if (isResubmit) {
        // ✅ Resubmit dengan logging
        debugPrint('🔄 [FORM] Calling resubmitAbsensi...');
        debugPrint('   - ID: ${widget.resubmitId}');
        debugPrint('   - Tipe: $_tipePengajuan');
        debugPrint('   - File: ${_pickedFile?.path}');
        debugPrint('   - Catatan: ${_catatanController.text}');
        
        result = await absensiProvider.resubmitAbsensi(
          absensiId: widget.resubmitId!,
          fileBukti: _pickedFile,
          catatan: _catatanController.text,
          catatanPanggilan: _catatanPanggilanController.text,
          tipe: _tipePengajuan,
        );
        
        debugPrint('📥 [FORM] Resubmit result: ${result['success']} - ${result['message']}');
      } else {
        // Pengajuan baru
        debugPrint('📤 [FORM] New submission - Tipe: $_tipePengajuan');
        
                if (_tipePengajuan == 'sakit') {
          result = await absensiProvider.absenSakit(
            fileBukti: _pickedFile!,
            catatan: _catatanController.text,
          );
        } else if (_tipePengajuan == 'cuti') {
          // Cuti dikirim sebagai izin dengan keterangan jenis cuti
          result = await absensiProvider.absenIzin(
            fileBukti: _pickedFile!,
            catatan: '[$_jenisCuti] ${_catatanController.text}',
            catatanPanggilan: _jenisCuti,
          );
        } else {
          result = await absensiProvider.absenIzin(
            fileBukti: _pickedFile!,
            catatan: _catatanController.text,
            catatanPanggilan: _catatanPanggilanController.text,
          );
        }
        
        debugPrint('📥 [FORM] New submission result: ${result['success']} - ${result['message']}');
      }

      if (mounted) {
        final message = result['message'] ?? 
                       (result['success'] == true ? 'Berhasil diajukan!' : 'Gagal mengirim pengajuan.');
        _showSnackBar(message);

        // ✅ Jika sukses, tutup form dan trigger refresh
        if (result['success'] == true) {
          debugPrint('✅ [FORM] Success! Closing form...');
          
          // Delay sebentar agar snackbar terlihat
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            if (isResubmit) {
              // Return true untuk trigger refresh di parent screen
              Navigator.of(context).pop(true);
            } else {
              // Clear form untuk pengajuan baru (optional: bisa langsung pop juga)
              _catatanController.clear();
              _catatanPanggilanController.clear();
              setState(() {
                _pickedFile = null;
              });
              
              // Optional: Auto-close form setelah submit berhasil
              // Navigator.of(context).pop(true);
            }
          }
        } else {
          debugPrint('❌ [FORM] Submission failed: ${result['message']}');
        }
      }
    } catch (e) {
      debugPrint('❌ [FORM] Exception during submit: $e');
      if (mounted) {
        _showSnackBar('Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildChoiceButton(String label, String value) {
    bool isSelected = _tipePengajuan == value;
    Color color = value == 'sakit' ? const Color(0xFFEF4444) : kAccentColor;

    return InkWell(
      onTap: () {
        setState(() {
          _tipePengajuan = value;
          if (value == 'sakit') {
            _catatanPanggilanController.clear();
          }
        });
        debugPrint('🔄 [FORM] Tipe changed to: $value');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isResubmit = widget.resubmitId != null;
    final label = isResubmit ? 'Ajukan Ulang' : 'Kirim Pengajuan';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: kPrimaryColor.withOpacity(0.3),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kAccentColor, width: 2.0),
        ),
        prefixIcon: Icon(icon, color: kAccentColor),
        labelStyle: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isResubmit = widget.resubmitId != null;
    final existing = widget.existingAbsensi;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(isResubmit ? 'Ajukan Ulang Pengajuan' : 'Form Pengajuan'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30.0),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              padding: const EdgeInsets.all(25.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.description_outlined, size: 40, color: kAccentColor),
                          const SizedBox(height: 10),
                          Text(
                            isResubmit 
                              ? 'Ajukan Ulang ${_tipePengajuan.toUpperCase()}' 
                              : 'Form Pengajuan Ketidakhadiran',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: kPrimaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isResubmit
                                ? 'Edit data dan unggah bukti terbaru sebelum mengajukan ulang.'
                                : 'Isi detail pengajuan ${(_tipePengajuan == 'sakit' ? 'Sakit' : 'Izin')} Anda',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 35, thickness: 1, color: Color(0xFFE0E0E0)),
                    
                    // Pilihan Jenis Pengajuan
                    const Text(
                      'Pilih Jenis Pengajuan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildChoiceButton('SAKIT', 'sakit')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildChoiceButton('IZIN', 'izin')),
                        const SizedBox(width: 10),
                        Expanded(child: _buildChoiceButton('CUTI', 'cuti')),
                      ],
                    ),
                    const SizedBox(height: 25),
                    
                    // Alasan Utama
                    _buildTextField(
                      controller: _catatanController,
                      labelText: 'Alasan Utama Ketidakhadiran',
                      hintText: 'Masukkan Alasan selengkapnya (Wajib diisi)',
                      icon: Icons.notes_outlined,
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alasan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),

                    // Dropdown jenis cuti (hanya untuk cuti)
                    if (_tipePengajuan == 'cuti') ...[
                      const Text(
                        'Jenis Cuti',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _jenisCuti,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kAccentColor, width: 2.0),
                          ),
                          prefixIcon: const Icon(Icons.beach_access_outlined, color: kAccentColor),
                          labelText: 'Pilih Jenis Cuti',
                          labelStyle: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'cuti_tahunan', child: Text('Cuti Tahunan (12 hari)')),
                          DropdownMenuItem(value: 'cuti_melahirkan', child: Text('Cuti Melahirkan')),
                          DropdownMenuItem(value: 'cuti_keguguran', child: Text('Cuti Keguguran')),
                          DropdownMenuItem(value: 'cuti_haji', child: Text('Cuti Ibadah Haji')),
                          DropdownMenuItem(value: 'cuti_umroh', child: Text('Cuti Ibadah Umroh')),
                          DropdownMenuItem(value: 'cuti_haid', child: Text('Cuti Haid (1 hari)')),
                          DropdownMenuItem(value: 'cuti_menikah', child: Text('Cuti Menikah (3 hari)')),
                          DropdownMenuItem(value: 'cuti_khitanan', child: Text('Cuti Khitanan Anak (2 hari)')),
                          DropdownMenuItem(value: 'cuti_baptis', child: Text('Cuti Baptis Anak (2 hari)')),
                          DropdownMenuItem(value: 'cuti_meninggal', child: Text('Cuti Meninggal Keluarga (2 hari)')),
                          DropdownMenuItem(value: 'change_off', child: Text('Change Off')),
                          DropdownMenuItem(value: 'unpaid_leave', child: Text('Unpaid Leave (1 hari)')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _jenisCuti = val!;
                          });
                        },
                        validator: (val) {
                          if (_tipePengajuan == 'cuti' && (val == null || val.isEmpty)) {
                            return 'Jenis cuti wajib dipilih';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                    ],
                    
                    // Catatan Panggilan (hanya untuk Izin)
                    if (_tipePengajuan == 'izin') ...[
                      _buildTextField(
                        controller: _catatanPanggilanController,
                        labelText: 'Catatan Kepentingan/Panggilan (Izin)',
                        hintText: 'Masukkan detail penting lainnya atau informasi panggilan. (Wajib diisi untuk Izin)',
                        icon: Icons.phone_callback_outlined,
                        maxLines: 2,
                        validator: (value) {
                          if (_tipePengajuan == 'izin' && (value == null || value.isEmpty)) {
                            return 'Catatan Kepentingan/Panggilan wajib diisi untuk Izin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                    ],
                    
                    // Upload Bukti
                    const Text(
                      'Unggah Bukti Dokumen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _showPickerOptions,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Pilih File (Surat Dokter/Dokumen Pendukung)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kAccentColor, width: 2.0),
                          ),
                          suffixIcon: const Icon(Icons.cloud_upload_outlined, color: kAccentColor),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                        ),
                        child: Text(
                          _pickedFile == null
                              ? (isResubmit && (existing?.fileBuktiUrl != null) 
                                  ? 'Pilih file baru (diperlukan)' 
                                  : 'File belum dipilih')
                              : 'File: ${_pickedFile!.path.split('/').last}',
                          style: TextStyle(
                            color: _pickedFile == null ? Colors.grey : Colors.black87,
                            fontWeight: _pickedFile == null ? FontWeight.normal : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Preview File Lama (untuk resubmit)
                    if (isResubmit && existing != null && existing.fileBuktiUrl != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bukti sebelumnya:', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                existing.fileBuktiUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Text(
                                    'Tidak bisa menampilkan file lama',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    
                    // Preview File Baru
                    if (_pickedFile != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isResubmit && existing?.fileBuktiUrl != null)
                            const Text(
                              'Bukti baru:', 
                              style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)
                            ),
                          const SizedBox(height: 8),
                          Center(
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kAccentColor.withOpacity(0.3), width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(_pickedFile!, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),
                    
                    // Submit Button
                    _buildSubmitButton(),
                    const SizedBox(height: 15),
                    
                    // Footer Info
                    Center(
                      child: Text(
                        isResubmit 
                          ? '*Pastikan bukti terbaru valid. Pengajuan ulang akan memulai proses approval kembali.' 
                          : '*Pengajuan ini akan diverifikasi oleh atasan Anda.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}