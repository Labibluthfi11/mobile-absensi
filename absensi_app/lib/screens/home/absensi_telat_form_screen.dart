import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../providers/absensi_provider.dart';
import '../../models/absensi_model.dart';
import 'custom_camera_screen.dart';

const Color kPrimaryColor = Color(0xFF4F46E5); // Deep Indigo
const Color kBackgroundColor = Color(0xFFF3F4F6); // Soft gray
const Color kWarningColor = Color(0xFFF59E0B);

// ======================================================================
// MODERN LOADING
// ======================================================================
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

class AbsensiTelatFormScreen extends StatefulWidget {
  final Absensi? absensiHariIni; 

  const AbsensiTelatFormScreen({super.key, this.absensiHariIni});

  @override
  State<AbsensiTelatFormScreen> createState() => _AbsensiTelatFormScreenState();
}

class _AbsensiTelatFormScreenState extends State<AbsensiTelatFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  File? _fileBukti;
  bool _isLoading = false;

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
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

  Future<void> _pickFile() async {
    final File? result = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
    );
    if (result != null && mounted) {
      setState(() => _fileBukti = result);
    }
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
       _showSnackBar('Foto bukti wajib diisi bos!', isSuccess: false);
      return;
    }

    final provider = Provider.of<AbsensiProvider>(context, listen: false);
    final absensi = widget.absensiHariIni ?? provider.currentDayAbsensi;

    if (absensi == null) {
      _showSnackBar('Data absen masuk ga ketemu, yakin udah absen?', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final result = await provider.pengajuanTelat(
        fileBukti: _fileBukti!, keterangan: _keteranganController.text.trim(), absensiId: absensi.id,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar(result['message'] ?? 'Alasan telat berhasil dikirim!', isSuccess: true);
        Navigator.of(context).pop(true);
      } else {
        // Cek apakah ini error jaringan "bapuk"
        if (result['isNetworkError'] == true) {
          _showBapukDialog(result['message']);
        } else {
          _showSnackBar(result['message'] ?? 'Gagal kirim bro.', isSuccess: false);
        }
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan fatal: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final provider = Provider.of<AbsensiProvider>(context, listen: false);
    final absensi = widget.absensiHariIni ?? provider.currentDayAbsensi;
    final lateMinutes = _hitungTelatMenit(absensi?.checkInAt);
    final checkInTime = absensi?.checkInAt != null
        ? DateFormat('HH:mm').format(DateTime.parse(absensi!.checkInAt!).toLocal())
        : '--:--';
    final tanggal = absensi?.checkInAt != null
        ? DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.parse(absensi!.checkInAt!).toLocal())
        : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Pengajuan Telat', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF1F2937), fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // INFO CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [lateMinutes > 0 ? kWarningColor : kPrimaryColor, lateMinutes > 0 ? const Color(0xFFD97706) : const Color(0xFF4338CA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: (lateMinutes > 0 ? kWarningColor : kPrimaryColor).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Absen', style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(tanggal, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildInfoChip(Icons.login_rounded, 'Masuk', checkInTime, Colors.white),
                        const SizedBox(width: 12),
                        _buildInfoChip(Icons.schedule_rounded, 'Aturan', '08:00', Colors.white70),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          Icons.timer_off_rounded,
                          'Telat',
                          lateMinutes > 0 ? '$lateMinutes mnt' : 'Aman',
                          lateMinutes > 0 ? Colors.red.shade100 : Colors.green.shade300,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (lateMinutes == 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200, width: 2)),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green.shade500, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('Jam masuk Anda aman, tidak perlu isi form alasan keterlambatan hari ini.', style: TextStyle(fontFamily: 'Poppins', color: Colors.green.shade800, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

              if (lateMinutes > 0) ...[
                const Text('Alasan Keterlambatan', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 12),
                
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 2)),
                  child: TextFormField(
                    controller: _keteranganController,
                    maxLines: 4,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF1F2937)),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Ban bocor di jalan tol, hujan deras, jalan dialihkan...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Keterangan gaboleh kosong';
                      if (v.trim().length < 10) return 'Tulis detail dong, minimal 10 huruf bro';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Foto Bukti Nyata', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text('Sertakan foto biar atasan gampang ACC', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    height: _fileBukti != null ? 220 : 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _fileBukti != null ? kPrimaryColor : Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: _fileBukti != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_fileBukti!, fit: BoxFit.cover),
                                Positioned(
                                  top: 12, right: 12,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _fileBukti = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded, size: 32, color: kPrimaryColor)
                              ),
                              const SizedBox(height: 12),
                              Text('Tap untuk buka kamera', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: kWarningColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kWarningColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const _ModernLoading(color: Colors.white)
                        : const Text('AJUKAN ALASAN TELAT', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontFamily: 'Poppins', color: valueColor, fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}