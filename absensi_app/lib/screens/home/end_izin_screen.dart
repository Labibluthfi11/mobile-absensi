import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/izin_keluar_provider.dart';
import '../../api/api.service.dart';
import 'custom_camera_screen.dart';

class EndIzinScreen extends StatefulWidget {
  const EndIzinScreen({Key? key}) : super(key: key);

  @override
  _EndIzinScreenState createState() => _EndIzinScreenState();
}

class _EndIzinScreenState extends State<EndIzinScreen> {
  final TextEditingController _keteranganController = TextEditingController();
  File? _dokumenKembali;
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
    final apiService = Provider.of<ApiService>(context, listen: false);
    provider.setLoading(true);

    try {
      final res = await apiService.endIzinKeluar(
        keteranganKembali: _keteranganController.text,
        dokumenKembali: _dokumenKembali!,
      );

      if (res['statusCode'] == 200 || res['statusCode'] == 201) {
        provider.ubahStatusIzinBerjalan(false);
        
        if (res['is_pelanggaran'] == true) {
           _tampilkanDialogPelanggaran();
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin berhasil diselesaikan.'), backgroundColor: Colors.green));
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
          icon: const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 64),
          title: const Text('Peringatan Pelanggaran!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Izin ditarik namun melewati batas maksimal 2 Jam.\n\nStatus absensi Anda telah dicatat oleh sistem sebagai Pelanggaran!',
             textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  Navigator.of(context).pop(); 
                  Navigator.of(context).pop(); 
                },
                child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
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
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text('Selesaikan Izin', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
                _buildLabel('Keterangan Penyelesaian'),
                TextFormField(
                  controller: _keteranganController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.black87, fontSize: 15, fontFamily: 'Poppins'),
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
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.indigo.shade200, width: 2, style: BorderStyle.solid),
                    ),
                    child: _dokumenKembali == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded, size: 48, color: Colors.indigo.shade400),
                              const SizedBox(height: 8),
                              Text('Tap untuk mengambil foto bukti', style: TextStyle(color: Colors.indigo.shade600, fontWeight: FontWeight.w500)),
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
                      backgroundColor: Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: Colors.indigo.shade200,
                    ),
                    onPressed: provider.isLoading ? null : _submitEndIzin,
                    child: provider.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade700, fontFamily: 'Poppins')),
      );

  InputDecoration _inputDecoration(String hint, IconData prefixIcon) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Poppins', fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(prefixIcon, color: Colors.indigo.shade300),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.indigo.shade500, width: 2)),
      );
}
