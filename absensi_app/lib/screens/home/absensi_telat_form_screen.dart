import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/absensi_provider.dart';
import '../../models/absensi_model.dart';

class AbsensiTelatFormScreen extends StatefulWidget {
  final Absensi? absensiHariIni; // null = dari home, isi = dari riwayat

  const AbsensiTelatFormScreen({super.key, this.absensiHariIni});

  @override
  State<AbsensiTelatFormScreen> createState() => _AbsensiTelatFormScreenState();
}

class _AbsensiTelatFormScreenState extends State<AbsensiTelatFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  File? _fileBukti;
  bool _isLoading = false;

  static const Color kPrimaryColor = Color(0xFF1E3A8A);
  static const Color kWarningColor = Color(0xFFB45309);

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.camera,
    imageQuality: 70,
  );
  if (picked != null) setState(() => _fileBukti = File(picked.path));
}

  int _hitungTelatMenit(String? checkInAt) {
    if (checkInAt == null) return 0;
    final checkIn = DateTime.parse(checkInAt).toLocal();
    final standardTime = DateTime(checkIn.year, checkIn.month, checkIn.day, 8, 0);
    if (checkIn.isAfter(standardTime)) {
      return checkIn.difference(standardTime).inMinutes;
    }
    return 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fileBukti == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    final provider = Provider.of<AbsensiProvider>(context, listen: false);
    final absensi = widget.absensiHariIni ?? provider.currentDayAbsensi;

    if (absensi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data absensi hari ini tidak ditemukan. Pastikan sudah absen masuk.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await provider.pengajuanTelat(
      fileBukti: _fileBukti!,
      keterangan: _keteranganController.text.trim(),
      absensiId: absensi.id,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Pengajuan berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Terjadi kesalahan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AbsensiProvider>(context, listen: false);
    final absensi = widget.absensiHariIni ?? provider.currentDayAbsensi;
    final lateMinutes = _hitungTelatMenit(absensi?.checkInAt);
    final checkInTime = absensi?.checkInAt != null
        ? DateFormat('HH:mm').format(DateTime.parse(absensi!.checkInAt!).toLocal())
        : '--:--';
    final tanggal = absensi?.checkInAt != null
        ? DateFormat('EEEE, d MMMM yyyy', 'id_ID')
            .format(DateTime.parse(absensi!.checkInAt!).toLocal())
        : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Pengajuan Keterangan Telat',
            style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // INFO CARD KETERLAMBATAN
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Keterlambatan',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(tanggal,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoChip(Icons.login_rounded, 'Jam Masuk', checkInTime, Colors.white),
                        const SizedBox(width: 12),
                        _buildInfoChip(Icons.schedule_rounded, 'Jam Standar', '08:00', Colors.white70),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.timer_off_rounded,
                          'Terlambat',
                          lateMinutes > 0 ? '$lateMinutes menit' : 'Tidak telat',
                          lateMinutes > 0 ? const Color(0xFFFBBF24) : Colors.green.shade300,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // WARNING kalau tidak telat
              if (lateMinutes == 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Anda tidak tercatat terlambat hari ini. Pengajuan tidak diperlukan.',
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              if (lateMinutes > 0) ...[
                // KETERANGAN
                const Text('Keterangan Alasan Terlambat',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kPrimaryColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _keteranganController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Ban bocor di jalan, kehujanan deras, macet parah...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
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
                      borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Keterangan tidak boleh kosong';
                    if (v.trim().length < 10) return 'Keterangan minimal 10 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // FOTO BUKTI
                const Text('Foto Bukti',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kPrimaryColor)),
                const SizedBox(height: 4),
                Text('Upload foto bukti keterlambatan Anda (ban bocor, kondisi jalan, dll)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    height: _fileBukti != null ? 200 : 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _fileBukti != null ? kPrimaryColor : Colors.grey.shade300,
                        width: _fileBukti != null ? 2 : 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _fileBukti != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_fileBukti!, fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _fileBukti = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Tap untuk upload foto bukti',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('JPG, PNG, PDF (maks 2MB)',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // TOMBOL SUBMIT
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Ajukan Keterangan Telat',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.white54),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}