import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';

const Color kPrimaryColor = Color(0xFF152C5C);
const Color kAccentColor = Color(0xFF3B82F6);
const Color kBackgroundColor = Color(0xFFF7F9FB);

// ✅ Konfigurasi jenis cuti: maksimal hari & apakah memotong jatah tahunan
const Map<String, Map<String, dynamic>> _cutiConfig = {
  'cuti_tahunan':   {'label': 'Cuti Tahunan',             'maxDays': 12,  'potongJatah': true},
  'cuti_melahirkan':{'label': 'Cuti Melahirkan',           'maxDays': 90,  'potongJatah': false},
  'cuti_keguguran': {'label': 'Cuti Keguguran',            'maxDays': 45,  'potongJatah': false},
  'cuti_haji':      {'label': 'Cuti Ibadah Haji',          'maxDays': 12,  'potongJatah': true},
  'cuti_umroh':     {'label': 'Cuti Ibadah Umroh',         'maxDays': 12,  'potongJatah': true},
  'cuti_menikah':   {'label': 'Cuti Menikah',              'maxDays': 3,   'potongJatah': false},
  'cuti_khitanan':  {'label': 'Cuti Khitanan Anak',        'maxDays': 2,   'potongJatah': false},
  'cuti_baptis':    {'label': 'Cuti Baptis Anak',          'maxDays': 2,   'potongJatah': false},
  'cuti_meninggal': {'label': 'Cuti Meninggal Keluarga',   'maxDays': 2,   'potongJatah': false},
  'change_off':     {'label': 'Change Off',                'maxDays': 1,   'potongJatah': false},
  'unpaid_leave':   {'label': 'Unpaid Leave',              'maxDays': 30,  'potongJatah': false},
};

class SakitFormScreen extends StatefulWidget {
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

  String _tipePengajuan = 'sakit';
  String _jenisCuti = 'cuti_tahunan';

  // ✅ Date picker
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingAbsensi != null) {
      _tipePengajuan = (widget.existingAbsensi!.tipe ?? 'sakit').toLowerCase();
      _catatanController.text = widget.existingAbsensi!.keterangan ?? '';
      if (_tipePengajuan == 'izin') {
        _catatanPanggilanController.text = widget.existingAbsensi!.catatanAdmin ?? '';
      }
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _catatanPanggilanController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int get _jumlahHariDipilih {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  int get _maxHariJenisCuti {
    return _cutiConfig[_jenisCuti]?['maxDays'] as int? ?? 30;
  }

  bool get _potongJatahTahunan {
    return _cutiConfig[_jenisCuti]?['potongJatah'] as bool? ?? false;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih tanggal';
    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date kalau start date lebih besar
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      _showSnackBar('Pilih tanggal mulai dulu!');
      return;
    }

    // Max end date berdasarkan jenis cuti
    final maxEndDate = _startDate!.add(Duration(days: _maxHariJenisCuti - 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: maxEndDate,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<File?> _compressImage(File file) async {
    if (kIsWeb) return file;
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.path}_compressed.jpg',
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );
      return result != null ? File(result.path) : file;
    } catch (e) {
      debugPrint('❌ Error compressing image: $e');
      return file;
    }
  }

  Future<void> _takePicture() async {
    Navigator.pop(context);
    try {
      final XFile? img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (img != null) {
        final compressed = await _compressImage(File(img.path));
        if (mounted) setState(() => _pickedFile = compressed);
        _showSnackBar('Foto berhasil diunggah.');
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil foto.');
    }
  }

  Future<void> _pickFromGallery() async {
    Navigator.pop(context);
    try {
      final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img != null) {
        final compressed = await _compressImage(File(img.path));
        if (mounted) setState(() => _pickedFile = compressed);
        _showSnackBar('Gambar berhasil diunggah.');
      }
    } catch (e) {
      _showSnackBar('Gagal memilih file.');
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Bukti', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryColor)),
            const Divider(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: kAccentColor),
              title: const Text('Ambil Foto Langsung', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: _takePicture,
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: kAccentColor),
              title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: _pickFromGallery,
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: kPrimaryColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitForm() async {
    final isResubmit = widget.resubmitId != null;

    // ✅ GANTI DARI .kategori KE .employmentType.toLowerCase()
    final userType = Provider.of<AuthProvider>(context, listen: false).user?.employmentType.toLowerCase();

    // ✅ SESUAIKAN VARIABELNYA JADI userType
    if (_tipePengajuan == 'cuti' && userType != 'organik') {
      _showSnackBar('Fitur Cuti hanya tersedia untuk karyawan Organik.');
      return;
    }

    // ... Sisa kode validasi form lu di bawahnya

    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Periksa kembali form Anda.');
      return;
    }

    // Validasi tanggal wajib untuk cuti
    if (_tipePengajuan == 'cuti') {
      if (_startDate == null || _endDate == null) {
        _showSnackBar('Pilih tanggal mulai dan selesai cuti!');
        return;
      }

      // Validasi hari tidak melebihi maksimal
      if (_jumlahHariDipilih > _maxHariJenisCuti) {
        _showSnackBar('${_cutiConfig[_jenisCuti]?['label']} maksimal $_maxHariJenisCuti hari!');
        return;
      }

      // Validasi sisa cuti tahunan
      if (_potongJatahTahunan) {
        final user = Provider.of<AuthProvider>(context, listen: false).user;
        debugPrint('DEBUG_CUTI: User Object -> ${user?.toJson()}'); 
  debugPrint('DEBUG_CUTI: Sisa Cuti dari Provider -> ${user?.sisaCuti}');
  debugPrint('DEBUG_CUTI: Jumlah Hari diajukan -> $_jumlahHariDipilih');
        final sisaCuti = user?.sisaCuti ?? 0;
        if (_jumlahHariDipilih > sisaCuti) {
          _showSnackBar('Sisa cuti tahunan Anda tidak cukup! Sisa: $sisaCuti hari, Diajukan: $_jumlahHariDipilih hari.');
          return;
        }
      }
    }

    if (!isResubmit && _pickedFile == null) {
      _showSnackBar('Harap unggah bukti dokumen.');
      return;
    }
    if (isResubmit && _pickedFile == null) {
      _showSnackBar('Harap unggah bukti terbaru.');
      return;
    }
    if (_tipePengajuan == 'izin' && _catatanPanggilanController.text.isEmpty) {
      _showSnackBar('Catatan Kepentingan wajib diisi untuk Izin.');
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = Provider.of<AbsensiProvider>(context, listen: false);
    Map<String, dynamic> result = {'success': false, 'message': 'Tidak ada aksi.'};

    try {
      if (isResubmit) {
        result = await provider.resubmitAbsensi(
          absensiId: widget.resubmitId!,
          fileBukti: _pickedFile,
          catatan: _catatanController.text,
          catatanPanggilan: _catatanPanggilanController.text,
          tipe: _tipePengajuan,
        );
      } else if (_tipePengajuan == 'sakit') {
        result = await provider.absenSakit(
          fileBukti: _pickedFile!,
          catatan: _catatanController.text,
        );
      } else if (_tipePengajuan == 'cuti') {
        result = await provider.absenIzin(
          fileBukti: _pickedFile!,
          catatan: _catatanController.text,
          catatanPanggilan: _jenisCuti,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        result = await provider.absenIzin(
          fileBukti: _pickedFile!,
          catatan: _catatanController.text,
          catatanPanggilan: _catatanPanggilanController.text,
        );
      }

      if (mounted) {
        _showSnackBar(result['message'] ?? (result['success'] == true ? 'Berhasil!' : 'Gagal.'));
        if (result['success'] == true) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            if (isResubmit) {
              Navigator.of(context).pop(true);
            } else {
              _catatanController.clear();
              _catatanPanggilanController.clear();
              setState(() {
                _pickedFile = null;
                _startDate = null;
                _endDate = null;
              });
            }
          }
        }
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isResubmit = widget.resubmitId != null;
    final existing = widget.existingAbsensi;
    final authProvider = Provider.of<AuthProvider>(context);

    // ✅ GANTI YANG INI: Pakai employmentType terus dijadiin huruf kecil semua biar aman
    final String userType = authProvider.user?.employmentType.toLowerCase() ?? 'freelance'; 
    
    final sisaCuti = authProvider.user?.sisaCuti ?? 12;

    // ✅ SESUAIKAN JUGA DISINI: Pakai variabel userType tadi
    if (userType != 'organik' && _tipePengajuan == 'cuti') {
      _tipePengajuan = 'sakit';
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(isResubmit ? 'Ajukan Ulang Pengajuan' : 'Form Pengajuan'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Header
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.description_outlined, size: 40, color: kAccentColor),
                          const SizedBox(height: 10),
                          Text(
                            isResubmit ? 'Ajukan Ulang ${_tipePengajuan.toUpperCase()}' : 'Form Pengajuan Ketidakhadiran',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kPrimaryColor),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 35, thickness: 1, color: Color(0xFFE0E0E0)),

                    // Pilihan tipe
                    const Text('Pilih Jenis Pengajuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    const SizedBox(height: 10),
                                      Row(
                    children: [
                      Expanded(child: _buildChoiceButton('SAKIT', 'sakit', const Color(0xFFEF4444))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildChoiceButton('IZIN', 'izin', kAccentColor)),
                      
                      // ✅ Ganti 'userKategori' jadi 'userType' sesuai variabel yang lu buat di atas tadi
                      if (userType == 'organik') ...[
                        const SizedBox(width: 10),
                        Expanded(child: _buildChoiceButton('CUTI', 'cuti', const Color(0xFF10B981))),
                      ],
                    ],
                  ),
                    const SizedBox(height: 25),

                    // Dropdown jenis cuti
                    if (_tipePengajuan == 'cuti') ...[
                      const Text('Jenis Cuti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _jenisCuti,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: kAccentColor, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.beach_access_outlined, color: kAccentColor),
                          labelText: 'Pilih Jenis Cuti',
                          labelStyle: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                        ),
                        items: _cutiConfig.entries.map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value['label'] as String),
                        )).toList(),
                        onChanged: (val) {
                          setState(() {
                            _jenisCuti = val!;
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Info jenis cuti
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _potongJatahTahunan ? Colors.orange.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _potongJatahTahunan ? Colors.orange.shade200 : Colors.green.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _potongJatahTahunan ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                  color: _potongJatahTahunan ? Colors.orange : Colors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _potongJatahTahunan
                                      ? 'Memotong jatah cuti tahunan'
                                      : 'Tidak memotong jatah cuti tahunan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _potongJatahTahunan ? Colors.orange.shade800 : Colors.green.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Maksimal $_maxHariJenisCuti hari',
                              style: TextStyle(
                                color: _potongJatahTahunan ? Colors.orange.shade700 : Colors.green.shade700,
                                fontSize: 12,
                              ),
                            ),
                            if (_potongJatahTahunan)
                              Text(
                                'Sisa cuti Anda: $sisaCuti hari',
                                style: TextStyle(
                                  color: sisaCuti <= 3 ? Colors.red : Colors.orange.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date picker
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePicker(
                              label: 'Tanggal Mulai',
                              date: _startDate,
                              onTap: _pickStartDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDatePicker(
                              label: 'Tanggal Selesai',
                              date: _endDate,
                              onTap: _pickEndDate,
                            ),
                          ),
                        ],
                      ),

                      // Info jumlah hari
                      if (_startDate != null && _endDate != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _jumlahHariDipilih > _maxHariJenisCuti
                                ? Colors.red.shade50
                                : kPrimaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _jumlahHariDipilih > _maxHariJenisCuti
                                  ? Colors.red.shade200
                                  : kPrimaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _jumlahHariDipilih > _maxHariJenisCuti
                                    ? Icons.error_outline
                                    : Icons.calendar_today,
                                size: 16,
                                color: _jumlahHariDipilih > _maxHariJenisCuti
                                    ? Colors.red
                                    : kPrimaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_jumlahHariDipilih hari dipilih',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _jumlahHariDipilih > _maxHariJenisCuti
                                      ? Colors.red
                                      : kPrimaryColor,
                                ),
                              ),
                              if (_jumlahHariDipilih > _maxHariJenisCuti)
                                Text(
                                  ' (melebihi batas $_maxHariJenisCuti hari!)',
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    // Alasan
                    _buildTextField(
                      controller: _catatanController,
                      labelText: 'Alasan Ketidakhadiran',
                      hintText: 'Masukkan alasan selengkapnya',
                      icon: Icons.notes_outlined,
                      maxLines: 4,
                      validator: (v) => (v == null || v.isEmpty) ? 'Alasan tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 25),

                    // Catatan panggilan (izin)
                    if (_tipePengajuan == 'izin') ...[
                      _buildTextField(
                        controller: _catatanPanggilanController,
                        labelText: 'Catatan Kepentingan/Panggilan',
                        hintText: 'Wajib diisi untuk Izin',
                        icon: Icons.phone_callback_outlined,
                        maxLines: 2,
                        validator: (v) => (_tipePengajuan == 'izin' && (v == null || v.isEmpty))
                            ? 'Catatan wajib diisi untuk Izin'
                            : null,
                      ),
                      const SizedBox(height: 25),
                    ],

                    // Upload bukti
                    const Text('Unggah Bukti Dokumen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor)),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _showPickerOptions,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Pilih File',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kAccentColor, width: 2)),
                          suffixIcon: const Icon(Icons.cloud_upload_outlined, color: kAccentColor),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                        ),
                        child: Text(
                          _pickedFile == null ? 'File belum dipilih' : 'File: ${_pickedFile!.path.split('/').last}',
                          style: TextStyle(
                            color: _pickedFile == null ? Colors.grey : Colors.black87,
                            fontWeight: _pickedFile == null ? FontWeight.normal : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Preview file lama (resubmit)
                    if (isResubmit && existing != null && existing.fileBuktiUrl != null) ...[
                      const Text('Bukti sebelumnya:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Container(
                        height: 150, width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(existing.fileBuktiUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Text('Tidak bisa menampilkan file lama', style: TextStyle(color: Colors.grey))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Preview file baru
                    if (_pickedFile != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        height: 200, width: double.infinity,
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: kAccentColor.withOpacity(0.3), width: 2)),
                        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_pickedFile!, fit: BoxFit.cover)),
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text(isResubmit ? 'Ajukan Ulang' : 'Kirim Pengajuan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Text(
                        '*Pengajuan ini akan diverifikasi oleh atasan Anda.',
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

  Widget _buildChoiceButton(String label, String value, Color color) {
    final isSelected = _tipePengajuan == value;
    return InkWell(
      onTap: () => setState(() {
        _tipePengajuan = value;
        _startDate = null;
        _endDate = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: isSelected ? Colors.white : Colors.black87, fontSize: 15)),
        ),
      ),
    );
  }

  Widget _buildDatePicker({required String label, required DateTime? date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: date != null ? kAccentColor : Colors.grey.shade300, width: date != null ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: date != null ? kAccentColor : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  Text(
                    _formatDate(date),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: date != null ? kPrimaryColor : Colors.grey),
                  ),
                ],
              ),
            ),
          ],
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kAccentColor, width: 2)),
        prefixIcon: Icon(icon, color: kAccentColor),
        labelStyle: const TextStyle(color: kPrimaryColor, fontWeight:     FontWeight.w600),
      ),
      validator: validator,
    );
  }
}