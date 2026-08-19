import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:absensi_app/core/app_colors.dart';
import '../../providers/izin_keluar_provider.dart';
import '../../providers/absensi_provider.dart';
import '../../api/api.service.dart';
import '../../models/absensi_model.dart';
import 'custom_camera_screen.dart';

class EndIzinScreen extends StatefulWidget {
  final int? resubmitId;
  final Absensi? existingAbsensi;

  const EndIzinScreen({Key? key, this.resubmitId, this.existingAbsensi}) : super(key: key);

  @override
  _EndIzinScreenState createState() => _EndIzinScreenState();
}

class _EndIzinScreenState extends State<EndIzinScreen> {
  final TextEditingController _keteranganController = TextEditingController();
  File? _dokumenKembali;

  @override
  void initState() {
    super.initState();
    if (widget.existingAbsensi != null) {
      _keteranganController.text = widget.existingAbsensi!.keterangan ?? '';
    }
  }
  Future<void> _takePicture() async {
    final File? image = await Navigator.push<File>(
      context, 
      MaterialPageRoute(builder: (_) => const CustomCameraScreen(useBackCamera: true))
    );
    if (image != null && mounted) {
      setState(() => _dokumenKembali = image);
    }
  }

  void _submitEndIzin() async {
    if (_dokumenKembali == null || _keteranganController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wajib mengisi keterangan & foto bukti penyelesaian!')));
      return;
    }

    final provider = Provider.of<IzinKeluarProvider>(context, listen: false);
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    provider.setLoading(true);

    try {
      Map<String, dynamic> res;
      if (widget.resubmitId != null) {
        res = await absensiProvider.resubmitAnySubmission(
          absensiId: widget.resubmitId!,
          data: {
            'keterangan_kembali': _keteranganController.text,
            'dokumen_kembali': await MultipartFile.fromFile(_dokumenKembali!.path, filename: _dokumenKembali!.path.split('/').last),
          }
        );
      } else {
        res = await apiService.endIzinKeluar(
          keteranganKembali: _keteranganController.text,
          dokumenKembali: _dokumenKembali!,
        );
      }

      if (res['success'] == true) {
        if (widget.resubmitId == null) provider.ubahStatusIzinBerjalan(false);
        
        if (res['is_pelanggaran'] == true) {
           _tampilkanDialogPelanggaran();
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin berhasil diselesaikan.'), backgroundColor: AppColors.kSuccessColor));
           Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal menyelesaikan izin.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      provider.setLoading(false);
    }
  }

  void _tampilkanDialogPelanggaran() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.warning_rounded, color: AppColors.kErrorColor, size: 64),
          title: const Text('Izin Diselesaikan', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Izin Keluar diselesaikan, namun lewat batas maksimal 2 jam. Ini tercatat sebagai Pelanggaran.\n\nKeputusan mengenai sanksi atau tindakan selanjutnya akan ditentukan secara manual oleh admin dan akan diinformasikan melalui notifikasi terpisah.',
             textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.kErrorColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  Navigator.of(context).pop(); 
                  Navigator.of(context).pop(); 
                },
                child: const Text('Mengerti', style: TextStyle(color: AppColors.kCardColor)),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackgroundColor,
      appBar: AppBar(
        title: Text(widget.resubmitId != null ? 'Re-Submit Izin' : 'Selesaikan Izin', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.kCardColor,
        foregroundColor: AppColors.kTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<IzinKeluarProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.existingAbsensi != null && widget.existingAbsensi!.isRejected) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: AppColors.kErrorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.kErrorColor.withOpacity(0.4))),
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
                _buildLabel('Keterangan Penyelesaian'),
                TextFormField(
                  controller: _keteranganController,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.kTextPrimary, fontSize: 15, fontFamily: 'Poppins'),
                  decoration: _inputDecoration('Detail penyelesaian tugas/urusan...', Icons.edit_note_rounded),
                ),
                const SizedBox(height: 24),

                _buildLabel('Bukti Dokumen / Lokasi (*Kamera)'),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.kPrimaryColor.withOpacity(0.4), width: 2, style: BorderStyle.solid),
                    ),
                    child: _dokumenKembali == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded, size: 48, color: AppColors.kPrimaryColor),
                              const SizedBox(height: 8),
                              Text('Tap untuk mengambil foto bukti', style: TextStyle(color: AppColors.kPrimaryColor.withOpacity(0.8), fontWeight: FontWeight.w500)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_dokumenKembali!, fit: BoxFit.cover, width: double.infinity),
                          ),
                  ),
                ),
                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      foregroundColor: AppColors.kCardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppColors.kPrimaryColor.withOpacity(0.4),
                    ),
                    onPressed: provider.isLoading ? null : _submitEndIzin,
                    child: provider.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.kCardColor, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle_rounded, size: 20),
                              SizedBox(width: 10),
                              Text('Selesaikan Izin Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                            ],
                          ),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.kTextDark, fontFamily: 'Poppins')),
      );

  InputDecoration _inputDecoration(String hint, IconData prefixIcon) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.kTextSecondary, fontFamily: 'Poppins', fontSize: 14),
        filled: true,
        fillColor: AppColors.kCardColor,
        prefixIcon: Icon(prefixIcon, color: AppColors.kPrimaryColor.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.kBackgroundColor, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.kPrimaryColor, width: 2)),
      );
}
