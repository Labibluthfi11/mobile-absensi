import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/izin_keluar_provider.dart';
import '../../api/api.service.dart';
import 'custom_camera_screen.dart';

class StartIzinScreen extends StatefulWidget {
  const StartIzinScreen({Key? key}) : super(key: key);

  @override
  _StartIzinScreenState createState() => _StartIzinScreenState();
}

class _StartIzinScreenState extends State<StartIzinScreen> {
  String? _selectedTipeIzin;
  String? _selectedDurasi;
  final TextEditingController _alasanController = TextEditingController();
  File? _fotoSurat;
  
  Future<void> _takePicture() async {
    final File? image = await Navigator.push<File>(
      context, 
      MaterialPageRoute(builder: (_) => const CustomCameraScreen(useBackCamera: true))
    );
    if (image != null && mounted) {
      setState(() {
        _fotoSurat = image;
      });
    }
  }

  void _submitData() async {
    if (_selectedTipeIzin == null || _alasanController.text.isEmpty || _fotoSurat == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi form & upload foto terlebih dahulu!')));
      return;
    }

    final provider = Provider.of<IzinKeluarProvider>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    provider.setLoading(true);

    try {
      final res = await apiService.startIzinKeluar(
        tipeIzin: _selectedTipeIzin!,
        tipeDurasi: _selectedDurasi,
        alasanKeluar: _alasanController.text,
        fotoSurat: _fotoSurat!,
      );

      if (res['statusCode'] == 200 || res['statusCode'] == 201) {
        provider.ubahStatusIzinBerjalan(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin keluar berhasil diajukan!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal mengajukan izin.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      provider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isTugasKantor = _selectedTipeIzin == 'tugas_kantor';
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mulai Izin Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
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
                _buildLabel('Tipe Izin Outing'),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Pilihan Izin Keluar', Icons.assignment_rounded),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
                  value: _selectedTipeIzin,
                  items: const [
                    DropdownMenuItem(value: 'mendesak', child: Text('Mendesak (Max 2 Jam)', style: TextStyle(color: Colors.black87))),
                    DropdownMenuItem(value: 'tugas_kantor', child: Text('Keperluan Tugas Kantor', style: TextStyle(color: Colors.black87))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedTipeIzin = val;
                      if (!isTugasKantor) _selectedDurasi = null;
                    });
                  },
                ),
                const SizedBox(height: 20),

                if (isTugasKantor) ...[
                  _buildLabel('Durasi Waktu'),
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Pilih Durasi Tugas', Icons.timer_rounded),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
                    value: _selectedDurasi,
                    items: const [
                      DropdownMenuItem(value: 'setengah_hari', child: Text('Setengah Hari', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'satu_hari_full', child: Text('Satu Hari Penuh', style: TextStyle(color: Colors.black87))),
                    ],
                    onChanged: (val) => setState(() => _selectedDurasi = val),
                  ),
                  const SizedBox(height: 20),
                ],

                _buildLabel('Alasan & Tujuan Keluar'),
                TextFormField(
                  controller: _alasanController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.black87, fontSize: 15, fontFamily: 'Poppins'),
                  decoration: _inputDecoration('Tulis alasan dengan detail...', Icons.edit_note_rounded),
                ),
                const SizedBox(height: 24),

                _buildLabel('Lampiran Surat Jalan/Bukti (*Kamera)'),
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
                    child: _fotoSurat == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded, size: 48, color: Colors.indigo.shade400),
                              const SizedBox(height: 8),
                              Text('Tap untuk mengambil foto dokumen', style: TextStyle(color: Colors.indigo.shade600, fontWeight: FontWeight.w500)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_fotoSurat!, fit: BoxFit.cover, width: double.infinity),
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
                    onPressed: provider.isLoading ? null : _submitData,
                    child: provider.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.send_rounded, size: 20),
                              SizedBox(width: 10),
                              Text('Mulai Izin Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
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
