import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';
import 'package:intl/intl.dart';
import '../../providers/absensi_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/rejected_notice_widget.dart';
import '../../models/absensi_model.dart';
import 'package:dio/dio.dart';
import '../../services/image_compress_service.dart';
import 'package:absensi_app/core/app_colors.dart';
import 'package:absensi_app/widgets/custom_success_dialog.dart';

class HalfDayLeaveScreen extends StatefulWidget {
  final int? resubmitId;
  final Absensi? existingAbsensi;

  const HalfDayLeaveScreen({super.key, this.resubmitId, this.existingAbsensi});

  @override
  State<HalfDayLeaveScreen> createState() => _HalfDayLeaveScreenState();
}

class _HalfDayLeaveScreenState extends State<HalfDayLeaveScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _catatanController = TextEditingController();
  TimeOfDay? _jamPulang;
  final DateTime _tanggal = DateTime.now(); // Fixed to today
  File? _pickedFile;
  bool _isSubmitting = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _fadeController.forward();

    if (widget.existingAbsensi != null) {
      _catatanController.text = widget.existingAbsensi!.keterangan ?? '';
      if (widget.existingAbsensi!.checkOutAt != null) {
        final time = DateTime.tryParse(widget.existingAbsensi!.checkOutAt!);
        if (time != null) {
          _jamPulang = TimeOfDay(hour: time.hour, minute: time.minute);
        }
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _jamPulang ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.kPrimaryColor,
                  ),
            ),
            child: child!,
          )),
    );
    if (picked != null) setState(() => _jamPulang = picked);
  }

  Future<void> _pickImage() async {
    final XFile? img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      final compressed = await ImageCompressService.compressImage(File(img.path));
      setState(() => _pickedFile = compressed);
    }
  }

  Future<void> _submit() async {
    if (_jamPulang == null || _catatanController.text.isEmpty) {
      _showSnack('Lengkapi data jam dan keterangan!', isError: true);
      return;
    }
    if (widget.resubmitId == null && _pickedFile == null) {
      _showSnack('Unggah bukti terlebih dahulu!', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = Provider.of<AbsensiProvider>(context, listen: false);
    Map<String, dynamic> result;

    if (widget.resubmitId != null) {
      result = await provider.resubmitAnySubmission(
        absensiId: widget.resubmitId!,
        data: {
          'keterangan': _catatanController.text,
          'tipe': 'izin',
          'catatan_panggilan': 'izin_pulang_cepat',
          'jam_pulang_rencana': '${_jamPulang!.hour.toString().padLeft(2, '0')}:${_jamPulang!.minute.toString().padLeft(2, '0')}',
          if (_pickedFile != null) 'file_bukti': await MultipartFile.fromFile(_pickedFile!.path),
        }
      );
    } else {
      result = await provider.absenIzin(
        fileBukti: _pickedFile!,
        catatan: _catatanController.text,
        catatanPanggilan: 'izin_pulang_cepat',
        startDate: _tanggal,
        endDate: _tanggal,
        jamPulangRencana: '${_jamPulang!.hour.toString().padLeft(2, '0')}:${_jamPulang!.minute.toString().padLeft(2, '0')}',
      );
    }

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _showSuccessPopup();
    } else {
      _showSnack(result['message'] ?? 'Gagal', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.kErrorColor : AppColors.kSuccessColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontFamily: 'Poppins', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomSuccessDialog(
        title: 'Berhasil!',
        message: 'Pengajuan izin setengah hari berhasil dikirim.',
        onOk: () {
          Navigator.pop(context); // Tutup dialog
          Navigator.pop(context); // Kembali ke Home
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Izin Setengah Hari',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Gradient header background
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.kPrimaryDark, AppColors.kPrimaryColor, AppColors.kAccentColor],
              ),
            ),
          ),
          // Decorative soft circles
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    if (widget.existingAbsensi != null && widget.existingAbsensi!.isRejected)
                      RejectedNoticeWidget(note: widget.existingAbsensi!.catatanAdmin ?? 'Tidak ada catatan.'),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Isi detail pengajuan izin pulang cepat kamu di bawah ini.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildGlassCard(
                      child: Column(
                        children: [
                          _buildInfoField(
                            'Tanggal',
                            DateFormat('dd MMM yyyy').format(_tanggal),
                            Icons.calendar_today_rounded,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            'Jam Pulang',
                            _jamPulang == null
                                ? 'Pilih Jam'
                                : '${_jamPulang!.hour.toString().padLeft(2, '0')}:${_jamPulang!.minute.toString().padLeft(2, '0')}',
                            Icons.access_time_rounded,
                            _pickTime,
                            highlight: _jamPulang == null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    _sectionLabel('Alasan Izin'),
                    const SizedBox(height: 8),
                    _buildTextArea(),

                    const SizedBox(height: 20),
                    _sectionLabel('Bukti Pendukung'),
                    const SizedBox(height: 8),
                    _buildUploadCard(),

                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.kTextDark,
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryColor.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _catatanController,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Contoh: Ada keperluan keluarga mendadak...',
          hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade400, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.kPrimaryColor, width: 1.6),
          ),
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildUploadCard() {
    final hasImage = _pickedFile != null;
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasImage ? AppColors.kSuccessColor.withOpacity(0.4) : AppColors.kPrimaryColor.withOpacity(0.25),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.kPrimaryColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: hasImage
                  ? Image.file(
                      _pickedFile!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.kPrimaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_photo_alternate_rounded,
                          color: AppColors.kPrimaryColor, size: 30),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasImage ? 'Bukti Terpilih' : 'Unggah Bukti',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasImage ? 'Tap untuk ganti foto' : 'Foto/screenshot pendukung izin',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasImage ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: hasImage ? AppColors.kSuccessColor : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [AppColors.kPrimaryDark, AppColors.kAccentColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.kPrimaryColor.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Kirim Pengajuan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  // Helper untuk field yang tidak bisa diklik (hanya info)
  Widget _buildInfoField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.kPrimaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.kPrimaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.kPrimaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.kTextPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value, IconData icon, VoidCallback onTap,
      {bool highlight = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? AppColors.kAccentColor.withOpacity(0.06) : AppColors.kPrimaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: highlight
              ? Border.all(color: AppColors.kAccentColor.withOpacity(0.3), width: 1.2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.kPrimaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.kPrimaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontFamily: 'Poppins')),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: AppColors.kTextPrimary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
