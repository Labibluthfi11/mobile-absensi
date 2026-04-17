import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_io/io.dart';
import 'dart:math' as math;
import '../../providers/absensi_provider.dart';
import 'package:intl/intl.dart';
import 'absensi_pulang_screen.dart'; // konstanta warna

// ======================================================================
// MODERN LOADING
// ======================================================================
class _ModernLoading extends StatefulWidget {
  final Color color;
  const _ModernLoading({this.color = Colors.white});
  @override
  State<_ModernLoading> createState() => _ModernLoadingState();
}

class _ModernLoadingState extends State<_ModernLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
                  child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: widget.color, shape: BoxShape.circle)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ======================================================================
// ABSENSI LEMBUR SCREEN — Form only, no camera/location
// ======================================================================
class AbsensiLemburScreen extends StatefulWidget {
  const AbsensiLemburScreen({super.key});

  @override
  State<AbsensiLemburScreen> createState() => _AbsensiLemburScreenState();
}

class _AbsensiLemburScreenState extends State<AbsensiLemburScreen> {
  List<File> _hasilKerjaFiles = [];

  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _goalsController = TextEditingController();
  final TextEditingController _jamMulaiController = TextEditingController();
  final TextEditingController _jamSelesaiController = TextEditingController();
  bool _istirahatChecked = false;

  @override
  void dispose() {
    _keteranganController.dispose();
    _goalsController.dispose();
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 24),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white))),
        ],
      ),
      backgroundColor: isSuccess ? kSuccessColor : kErrorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(20),
      elevation: 8,
    ));
  }

  Future<void> _pickHasilKerjaImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(
        imageQuality: 70, maxWidth: 1280, maxHeight: 1280);

    if (pickedFiles.isNotEmpty && mounted) {
      if (pickedFiles.length > 5) {
        _showSnackBar('Maksimal 5 foto ya bos!', isSuccess: false);
        return;
      }
      setState(() => _hasilKerjaFiles =
          pickedFiles.map((xFile) => File(xFile.path)).toList());
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: kLemburColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final now = DateTime.now();
      final formatted = DateFormat('HH:mm').format(
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute));
      setState(() => controller.text = formatted);
    }
  }

  Future<void> _submitLembur() async {
    final absensiProvider =
        Provider.of<AbsensiProvider>(context, listen: false);

    if (absensiProvider.isLoading) return;

    if (_hasilKerjaFiles.isEmpty) {
      _showSnackBar('Wajib upload minimal 1 foto bukti kerja lembur!',
          isSuccess: false);
      return;
    }

    final isFormValid = _keteranganController.text.trim().isNotEmpty &&
        _jamMulaiController.text.trim().isNotEmpty &&
        _jamSelesaiController.text.trim().isNotEmpty;

    if (!isFormValid) {
      _showSnackBar(
          'Lengkapi form lembur (Jam Mulai, Selesai, dan Keterangan)',
          isSuccess: false);
      return;
    }

    try {
      absensiProvider.setIsLoading(true);
      absensiProvider.setErrorMessage(null);
      await Future.delayed(const Duration(milliseconds: 600));

      final result = await absensiProvider.submitLembur(
        jamMulai: _jamMulaiController.text.trim(),
        jamSelesai: _jamSelesaiController.text.trim(),
        istirahat: _istirahatChecked,
        keterangan: _keteranganController.text.trim(),
        goals: _goalsController.text.trim(),
        hasilKerjaFiles: _hasilKerjaFiles,
      );

      if (result['success'] == true && mounted) {
        _showSuccessDialog();
      } else {
        // Cek apakah ini error jaringan "bapuk"
        if (result['isNetworkError'] == true && mounted) {
          _showBapukDialog(result['message']);
        } else if (mounted) {
          absensiProvider
              .setErrorMessage(result['message'] ?? 'Pengajuan Lembur Gagal.');
          _showSnackBar(result['message'] ?? 'Gagal rek.', isSuccess: false);
        }
      }
    } catch (e) {
      absensiProvider
          .setErrorMessage('Terjadi error saat submit: ${e.toString()}');
      _showSnackBar('Ada yang rusak nih bos: $e', isSuccess: false);
    } finally {
      absensiProvider.setIsLoading(false);
    }
  }

  void _showBapukDialog(String? message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final Color errorColor = const Color(0xFFEF4444);
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
                      backgroundColor: errorColor, padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.beenhere_rounded,
                      color: Colors.green.shade500, size: 60),
                ),
                const SizedBox(height: 20),
                const Text('Pengajuan Lembur Tercatat!',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                    'Waktu Submit: ${DateFormat('HH:mm').format(DateTime.now())}',
                    style: const TextStyle(
                        fontFamily: 'Poppins', color: Colors.grey)),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0),
                    child: const Text('Tutup',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
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
    final absensiProvider = Provider.of<AbsensiProvider>(context);

    final bool isFormValid = _keteranganController.text.trim().isNotEmpty &&
        _jamMulaiController.text.trim().isNotEmpty &&
        _jamSelesaiController.text.trim().isNotEmpty &&
        _hasilKerjaFiles.isNotEmpty;

    final bool isButtonDisabled = absensiProvider.isLoading || !isFormValid;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Pengajuan Lembur',
            style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [kLemburColor, kLemburColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                      color: kLemburColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.more_time_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Formulir Lembur',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Isi detail lembur hari ini',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Card Detail Lembur ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border:
                    Border.all(color: kLemburColor.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: kLemburColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: kLemburColor.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.work_history_rounded,
                              color: kLemburColor, size: 20)),
                      const SizedBox(width: 12),
                      const Text('Detail Lembur',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Jam Mulai & Selesai
                  Row(
                    children: [
                      Expanded(
                          child: _buildModernTextField(
                              controller: _jamMulaiController,
                              hintText: 'Jam Mulai',
                              icon: Icons.access_time_rounded,
                              onTap: () => _selectTime(_jamMulaiController),
                              readOnly: true)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildModernTextField(
                              controller: _jamSelesaiController,
                              hintText: 'Jam Selesai',
                              icon: Icons.access_time_rounded,
                              onTap: () => _selectTime(_jamSelesaiController),
                              readOnly: true)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Istirahat checkbox
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.grey.shade200, width: 2)),
                    child: CheckboxListTile(
                      title: const Text('Diambil Istirahat?',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w600)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      value: _istirahatChecked,
                      activeColor: kLemburColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onChanged: absensiProvider.isLoading
                          ? null
                          : (v) => setState(
                              () => _istirahatChecked = v ?? false),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Keterangan
                  _buildModernTextField(
                      controller: _keteranganController,
                      hintText: 'Kerjain apa lu hari ini bro?',
                      icon: Icons.description_rounded,
                      maxLines: 3),
                  const SizedBox(height: 16),

                  // Goals
                  _buildModernTextField(
                      controller: _goalsController,
                      hintText: 'Goals yg kesampaian apa?',
                      icon: Icons.flag_rounded,
                      maxLines: 2),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Card Bukti Kerja ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.grey.shade100, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Bukti Kerja (Min 1, Max 5)',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937))),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickHasilKerjaImages,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _hasilKerjaFiles.isEmpty
                            ? Colors.grey.shade50
                            : Colors.white,
                        border: Border.all(
                            color: _hasilKerjaFiles.isNotEmpty
                                ? kLemburColor
                                : Colors.grey.shade200,
                            width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _hasilKerjaFiles.isEmpty
                          ? Column(
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    size: 40, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('Tekan untuk upload dari galeri',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade500)),
                              ],
                            )
                          : Column(
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _hasilKerjaFiles
                                      .map((f) => ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.file(f,
                                              width: 65,
                                              height: 65,
                                              fit: BoxFit.cover)))
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                    '${_hasilKerjaFiles.length} foto dipilih • Tap untuk ganti',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Tombol Submit ──
            Container(
              height: 56,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isButtonDisabled
                      ? []
                      : [
                          BoxShadow(
                              color: kSuccessColor.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5))
                        ]),
              child: ElevatedButton(
                onPressed: isButtonDisabled ? null : _submitLembur,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccessColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: absensiProvider.isLoading
                    ? const _ModernLoading(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded,
                              color: isButtonDisabled
                                  ? Colors.grey.shade500
                                  : Colors.white),
                          const SizedBox(width: 8),
                          Text('KIRIM PENGAJUAN LEMBUR',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isButtonDisabled
                                      ? Colors.grey.shade500
                                      : Colors.white,
                                  letterSpacing: 0.5)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField(
      {required TextEditingController controller,
      required String hintText,
      required IconData icon,
      int maxLines = 1,
      VoidCallback? onTap,
      bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 2)),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        onTap: onTap,
        readOnly: readOnly,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.normal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: Colors.grey.shade400, size: 20)
              : null,
        ),
      ),
    );
  }
}
