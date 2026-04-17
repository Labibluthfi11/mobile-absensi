import 'package:universal_io/io.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart';

const Color kPrimaryColor = Color(0xFF4F46E5); // Deep Indigo
const Color kBackgroundColor = Color(0xFFF3F4F6); // Soft gray
const Color kCardColor = Colors.white;

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

// ----------------------------------------------------------------------
// MODERN LOADING (Bouncing dots)
// ----------------------------------------------------------------------
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

  int get _jumlahHariDipilih => (_startDate == null || _endDate == null) ? 0 : _endDate!.difference(_startDate!).inDays + 1;
  int get _maxHariJenisCuti => _cutiConfig[_jenisCuti]?['maxDays'] as int? ?? 30;
  bool get _potongJatahTahunan => _cutiConfig[_jenisCuti]?['potongJatah'] as bool? ?? false;

  String _formatDate(DateTime? date) => date == null ? 'Pilih tanggal' : DateFormat('dd MMM yyyy').format(date);

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: kPrimaryColor)), child: child!),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      _showSnackBar('Pilih tanggal mulai terlebih dahulu.', isSuccess: false);
      return;
    }
    final maxEndDate = _startDate!.add(Duration(days: _maxHariJenisCuti - 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: maxEndDate,
      builder: (ctx, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: kPrimaryColor)), child: child!),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<File?> _compressImage(File file) async {
    if (kIsWeb) return file;
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path, '${file.path}_compressed.jpg', quality: 70, minWidth: 1024, minHeight: 1024,
      );
      return result != null ? File(result.path) : file;
    } catch (e) {
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
      }
    } catch (e) { _showSnackBar('Gagal mengambil foto.', isSuccess: false); }
  }

  Future<void> _pickFromGallery() async {
    Navigator.pop(context);
    try {
      final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img != null) {
        final compressed = await _compressImage(File(img.path));
        if (mounted) setState(() => _pickedFile = compressed);
      }
    } catch (e) { _showSnackBar('Gagal memilih gambar.', isSuccess: false); }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text('Unggah Bukti Dokumen', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _takePicture,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.shade100)),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt_rounded, color: Colors.blue, size: 32),
                          SizedBox(height: 12),
                          Text('Kamera', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.blue))
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickFromGallery,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purple.shade100)),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library_rounded, color: Colors.purple, size: 32),
                          SizedBox(height: 12),
                          Text('Galeri', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.purple))
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    ));
  }

  Future<void> _submitForm() async {
    final isResubmit = widget.resubmitId != null;
    final userType = Provider.of<AuthProvider>(context, listen: false).user?.employmentType.toLowerCase();

    if (_tipePengajuan == 'cuti' && userType != 'organik') {
      _showSnackBar('Fitur Cuti hanya tersedia untuk karyawan Organik.', isSuccess: false);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Periksa kembali form pendaftaran Anda.', isSuccess: false);
      return;
    }

    if (_tipePengajuan == 'cuti') {
      if (_startDate == null || _endDate == null) {
        _showSnackBar('Pilih rentang tanggal cuti!', isSuccess: false);
        return;
      }
      if (_potongJatahTahunan) {
        final sisaCuti = Provider.of<AuthProvider>(context, listen: false).user?.sisaCuti ?? 0;
        if (_jumlahHariDipilih > sisaCuti) {
          _showSnackBar('Sisa cuti tidak cukup (Sisa: $sisaCuti, Diajukan: $_jumlahHariDipilih)', isSuccess: false);
          return;
        }
      }
    }

    if (!isResubmit && _pickedFile == null) {
      _showSnackBar('Bukti medis/dokumen wajib diunggah!', isSuccess: false);
      return;
    }
    if (isResubmit && _pickedFile == null) {
      _showSnackBar('Harap unggah bukti dokumen terbaru!', isSuccess: false);
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = Provider.of<AbsensiProvider>(context, listen: false);
    Map<String, dynamic> result = {'success': false, 'message': 'Gagal'};

    try {
      await Future.delayed(const Duration(milliseconds: 600)); // Smooth loading
      if (isResubmit) {
        result = await provider.resubmitAbsensi(
          absensiId: widget.resubmitId!,
          fileBukti: _pickedFile,
          catatan: _catatanController.text,
          catatanPanggilan: _catatanPanggilanController.text,
          tipe: _tipePengajuan,
        );
      } else if (_tipePengajuan == 'sakit') {
        result = await provider.absenSakit(fileBukti: _pickedFile!, catatan: _catatanController.text);
      } else if (_tipePengajuan == 'cuti') {
        result = await provider.absenIzin(
          fileBukti: _pickedFile!, catatan: _catatanController.text, catatanPanggilan: _jenisCuti, startDate: _startDate, endDate: _endDate,
        );
      } else {
        result = await provider.absenIzin(
          fileBukti: _pickedFile!, catatan: _catatanController.text, catatanPanggilan: _catatanPanggilanController.text,
        );
      }

      if (mounted) {
        if (result['success'] == true) {
          _showSnackBar(result['message'] ?? 'Berhasil mengumpulkan!', isSuccess: true);
          if (isResubmit) {
            Navigator.of(context).pop(true);
          } else {
            _catatanController.clear();
            _catatanPanggilanController.clear();
            setState(() { _pickedFile = null; _startDate = null; _endDate = null; });
          }
        } else {
          // Cek apakah ini error jaringan "bapuk"
          if (result['isNetworkError'] == true) {
             _showBapukDialog(result['message']);
          } else {
             _showSnackBar(result['message'] ?? 'Terjadi Kesalahan.', isSuccess: false);
          }
        }
      }
    } catch (e) {
      _showSnackBar('Kesalahan fatal: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showBapukDialog(String? message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.signal_wifi_connected_no_internet_4_rounded, color: Colors.red.shade500, size: 60),
                ),
                const SizedBox(height: 20),
                const Text('Waduh, Koneksi Putus!', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(message ?? 'Internet lu bapuk banget boy asli.', style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0
                    ),
                    child: const Text('Coba Lagi Nanti', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isResubmit = widget.resubmitId != null;
    final existing = widget.existingAbsensi;
    final userType = Provider.of<AuthProvider>(context).user?.employmentType.toLowerCase() ?? 'freelance';
    final sisaCuti = Provider.of<AuthProvider>(context).user?.sisaCuti ?? 12;

    if (userType != 'organik' && _tipePengajuan == 'cuti') _tipePengajuan = 'sakit';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(isResubmit ? 'Re-Submit Pengajuan' : 'Form Pengajuan', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              const Text('Kategori Pengajuan', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildChoiceCard('Sakit', 'sakit', const Color(0xFFEF4444), Icons.local_hospital_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildChoiceCard('Izin', 'izin', const Color(0xFF8B5CF6), Icons.event_note_rounded)),
                  if (userType == 'organik') ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildChoiceCard('Cuti', 'cuti', const Color(0xFF10B981), Icons.beach_access_rounded)),
                  ],
                ],
              ),
              const SizedBox(height: 32),

              if (_tipePengajuan == 'cuti') ...[
                const Text('Rincian Cuti', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 2)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _jenisCuti,
                      icon: const Icon(Icons.expand_more_rounded, color: kPrimaryColor),
                      style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.w600),
                      items: _cutiConfig.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['label'] as String))).toList(),
                      onChanged: (val) {
                        setState(() { _jenisCuti = val!; _startDate = null; _endDate = null; });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _potongJatahTahunan ? Colors.orange.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(_potongJatahTahunan ? Icons.warning_rounded : Icons.check_circle_rounded, color: _potongJatahTahunan ? Colors.orange.shade600 : Colors.green.shade600, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_potongJatahTahunan ? 'Memotong jatah cuti' : 'Tidak memotong cuti', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: _potongJatahTahunan ? Colors.orange.shade800 : Colors.green.shade800, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('Maks. pengajuan $_maxHariJenisCuti hari.', style: TextStyle(fontFamily: 'Poppins', color: _potongJatahTahunan ? Colors.orange.shade700 : Colors.green.shade700, fontSize: 12)),
                            if (_potongJatahTahunan) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.orange.shade200, borderRadius: BorderRadius.circular(10)),
                                child: Text('Sisa Cuti: $sisaCuti Hari', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orange.shade900)),
                              )
                            ]
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: _buildDatePicker(label: 'Mulai', date: _startDate, onTap: _pickStartDate)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDatePicker(label: 'Selesai', date: _endDate, onTap: _pickEndDate)),
                  ],
                ),
                
                if (_startDate != null && _endDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _jumlahHariDipilih > _maxHariJenisCuti ? Colors.red.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Row(
                      children: [
                        Icon(_jumlahHariDipilih > _maxHariJenisCuti ? Icons.error_rounded : Icons.event_available_rounded, size: 18, color: _jumlahHariDipilih > _maxHariJenisCuti ? Colors.red : Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_jumlahHariDipilih > _maxHariJenisCuti ? 'Total $_jumlahHariDipilih Hari (Melebihi Batas!)' : 'Total Cuti: $_jumlahHariDipilih Hari', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12, color: _jumlahHariDipilih > _maxHariJenisCuti ? Colors.red.shade700 : Colors.blue.shade700)),
                        )
                      ],
                    ),
                  )
                ],
                const SizedBox(height: 32),
              ],

              const Text('Keterangan', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 12),
              _buildModernTextField(
                controller: _catatanController,
                hintText: 'Tuliskan rincian alasan dengan jelas...',
                icon: Icons.notes_rounded,
                maxLines: 4,
                validator: (v) => (v == null || v.isEmpty) ? 'Detail pengajuan tidak boleh kosong!' : null,
              ),

              if (_tipePengajuan == 'izin') ...[
                const SizedBox(height: 20),
                const Text('Pihak Bersangkutan', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 12),
                _buildModernTextField(
                  controller: _catatanPanggilanController,
                  hintText: 'Contoh: Panggilan Sekolah / Dinas terkait',
                  icon: Icons.school_rounded,
                  validator: (v) => (_tipePengajuan == 'izin' && (v == null || v.isEmpty)) ? 'Wajib diisi untuk Izin' : null,
                ),
              ],
              const SizedBox(height: 32),

              const Text('Bukti Pendukung', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showPickerOptions,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _pickedFile != null ? kPrimaryColor : Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(_pickedFile != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, size: 40, color: _pickedFile != null ? kPrimaryColor : Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _pickedFile != null ? 'Dokumen Terlampir' : 'Tekan untuk mengunggah Surat/Foto',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: _pickedFile != null ? FontWeight.bold : FontWeight.normal, color: _pickedFile != null ? kPrimaryColor : Colors.grey.shade500),
                      ),
                      if (_pickedFile != null)
                        Padding(padding: const EdgeInsets.only(top: 6), child: Text(_pickedFile!.path.split('/').last, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),

              if (isResubmit && existing != null && existing.fileBuktiUrl != null && _pickedFile == null) ...[
                const SizedBox(height: 16),
                const Text('Dokumen Sebelumnya:', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  height: 140, width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(existing.fileBuktiUrl!, fit: BoxFit.cover)),
                ),
              ],

              if (_pickedFile != null) ...[
                const SizedBox(height: 16),
                Container(
                  height: 180, width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: kPrimaryColor.withOpacity(0.3), width: 3), borderRadius: BorderRadius.circular(16)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_pickedFile!, fit: BoxFit.cover)),
                )
              ],

              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0
                  ),
                  child: _isSubmitting
                      ? const _ModernLoading()
                      : Text(isResubmit ? 'Kirim Ulang' : 'Kirim Pengajuan', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard(String label, String value, Color color, IconData icon) {
    final bool isSelected = _tipePengajuan == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tipePengajuan = value;
          _startDate = null;
          _endDate = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade400, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade600))
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({required String label, required DateTime? date, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: date != null ? kPrimaryColor : Colors.grey.shade200, width: 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text(_formatDate(date), style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: date != null ? const Color(0xFF1F2937) : Colors.grey.shade400))),
                Icon(Icons.calendar_month_rounded, size: 16, color: date != null ? kPrimaryColor : Colors.grey.shade400)
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({required TextEditingController controller, required String hintText, required IconData icon, int maxLines = 1, String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 2)),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF1F2937)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.grey.shade400, size: 20) : null,
        ),
        validator: validator,
      ),
    );
  }
}