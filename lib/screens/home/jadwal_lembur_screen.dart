import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../api/api.service.dart';
import '../../models/absensi_model.dart';
import '../../providers/absensi_provider.dart';
import 'package:absensi_app/core/app_colors.dart';

class JadwalLemburScreen extends StatefulWidget {
  final int? resubmitId;
  final Absensi? existingAbsensi;

  const JadwalLemburScreen({super.key, this.resubmitId, this.existingAbsensi});

  @override
  State<JadwalLemburScreen> createState() => _JadwalLemburScreenState();
}

class _JadwalLemburScreenState extends State<JadwalLemburScreen> {
  DateTime? _selectedDate;
  final TextEditingController _keteranganController = TextEditingController();
  File? _fotoBukti;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAbsensi != null) {
      _keteranganController.text = widget.existingAbsensi!.keterangan ?? '';
      if (widget.existingAbsensi!.checkInAt != null) {
        _selectedDate = DateTime.tryParse(widget.existingAbsensi!.checkInAt!);
      }
    }
  }

  void _pilihTanggal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.kPrimaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _fotoBukti = File(pickedFile.path);
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _fotoBukti = null;
    });
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _keteranganController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<AbsensiProvider>(context, listen: false);
    final String tglStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final bool isResubmit = widget.resubmitId != null;

    try {
      Map<String, dynamic> result;

      if (isResubmit) {
        result = await provider.resubmitAnySubmission(
          absensiId: widget.resubmitId!,
          data: {
            'tanggal_lembur': tglStr,
            'keterangan': _keteranganController.text.trim(),
            if (_fotoBukti != null) 'foto_bukti': await MultipartFile.fromFile(_fotoBukti!.path, filename: _fotoBukti!.path.split('/').last),
          }
        );
      } else {
        result = await provider.submitLemburTerjadwal(
          tanggalLembur: tglStr,
          keterangan: _keteranganController.text.trim(),
          fotoBukti: _fotoBukti,
        );
      }

      if (!mounted) return;

      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Icon(Icons.check_circle_rounded,
                  color: AppColors.kSuccessColor, size: 60),
              content: Text(
                isResubmit ? 'Perbaikan lembur terjadwal berhasil disimpan!' : 'Pengajuan lembur terjadwal berhasil disimpan!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // pop dialog
                    Navigator.of(context).pop(); // pop screen
                  },
                  child: const Text('OK',
                      style: TextStyle(
                          color: AppColors.kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins')),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.kErrorColor,
            content: Text(result['message'] ?? 'Gagal mengajukan lembur',
                style: const TextStyle(fontFamily: 'Poppins')),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.kErrorColor,
          content: Text('Terjadi kesalahan: $e',
              style: const TextStyle(fontFamily: 'Poppins')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _selectedDate != null &&
        _keteranganController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.kBackgroundColor,
      appBar: AppBar(
        title: const Text('Lembur Terjadwal',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.existingAbsensi != null && widget.existingAbsensi!.isRejected) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: AppColors.kErrorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.kErrorColor.withOpacity(0.5))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alasan Penolakan:', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: AppColors.kErrorColor)),
                    const SizedBox(height: 4),
                    Text(widget.existingAbsensi!.catatanAdmin ?? 'Tidak ada catatan.', style: const TextStyle(fontFamily: 'Poppins', color: AppColors.kErrorColor)),
                  ],
                ),
              ),
            ],

            // CARD 1: Pilih Tanggal Lembur
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.kLemburColor, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.kLemburColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Tanggal Lembur',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextPrimary)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pilihTanggal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              color: AppColors.kPrimaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                      .format(_selectedDate!)
                                  : 'Belum dipilih',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: _selectedDate != null
                                    ? AppColors.kTextPrimary
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CARD 2: Keterangan
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.kLemburColor, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.kLemburColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keterangan Lembur',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextPrimary)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _keteranganController,
                    maxLines: 4,
                    onChanged: (v) => setState(() {}), // re-evaluate canSubmit
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.kTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Jelaskan kegiatan lembur yang akan dilakukan',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontFamily: 'Poppins'),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300, width: 1)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300, width: 1)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.kLemburColor, width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // CARD 3: Bukti Dokumen
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.kLemburColor, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.kLemburColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bukti Dokumen (Opsional)',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kTextPrimary)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _fotoBukti == null ? _pickImage : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _fotoBukti == null
                            ? Colors.grey.shade50
                            : Colors.green.shade50,
                        border: Border.all(
                            color: _fotoBukti == null
                                ? Colors.grey.shade300
                                : Colors.green.shade300,
                            width: 2,
                            style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: _fotoBukti == null
                          ? Column(
                              children: [
                                Icon(Icons.upload_file,
                                    size: 40, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('Upload Bukti Dokumen (Opsional)',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text('JPG, PNG, atau PDF • Maks 2MB',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Colors.grey.shade400)),
                              ],
                            )
                          : Row(
                              children: [
                                const Icon(Icons.insert_drive_file,
                                    color: Colors.green, size: 30),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fotoBukti!.path.split('/').last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.close,
                                      color: AppColors.kErrorColor),
                                )
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // SUBMIT BUTTON
            SizedBox(
              height: 56,
              child: ElevatedButton(
              onPressed: (!canSubmit || _isLoading) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kLemburColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.resubmitId != null ? 'AJUKAN ULANG LEMBUR' : 'AJUKAN LEMBUR TERJADWAL',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5),
                    ),
              ),

            ),
          ],
        ),
      ),
    );
  }
}
