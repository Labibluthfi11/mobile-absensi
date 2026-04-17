import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'custom_camera_screen.dart';
import 'package:universal_io/io.dart'; 
import 'dart:async'; 
import 'dart:math' as math;
import '../../providers/absensi_provider.dart'; 
import 'package:intl/intl.dart';

const Color kPrimaryColor = Color(0xFF4F46E5); // Deep Indigo
const Color kBackgroundColor = Color(0xFFF3F4F6);
const Color kSuccessColor = Color(0xFF10B981);
const Color kErrorColor = Color(0xFFEF4444);
const Color kLemburColor = Color(0xFFF59E0B); // Amber for Lembur

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

class AbsensiPulangScreen extends StatefulWidget {
  final bool? lembur; 
  const AbsensiPulangScreen({super.key, this.lembur});

  @override
  State<AbsensiPulangScreen> createState() => _AbsensiPulangScreenState();
}

class _AbsensiPulangScreenState extends State<AbsensiPulangScreen> {
  File? _capturedImageFile;
  bool _isPhotoTaken = false; 
  Position? _currentPosition;

  late String _timeString;
  late String _dateString;
  late Timer _timer;
  
  String _locationStatus = 'Memuat lokasi...';

  // Early Checkout (Sakit) state
  bool _isPulangSakit = false;
  File? _fileBuktiSakit;
  final TextEditingController _keteranganSakitController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID'; 
    _timeString = DateFormat('HH:mm:ss').format(DateTime.now());
    _dateString = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    _checkLocation();
  }

  @override
  void dispose() {
    _timer.cancel();
    _keteranganSakitController.dispose();
    super.dispose();
  }
  
  void _updateTime() {
    if (mounted) setState(() => _timeString = DateFormat('HH:mm:ss').format(DateTime.now()));
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

  Future<void> _pickBuktiSakit() async {
    try {
      final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (img != null) {
        final compressed = await _compressImage(File(img.path));
        if (mounted) setState(() => _fileBuktiSakit = compressed);
      }
    } catch (e) { _showSnackBar('Gagal memilih gambar bukti.', isSuccess: false); }
  }
  
  Future<void> _checkLocation() async {
    setState(() {
      _locationStatus = 'Memuat lokasi...';
      _currentPosition = null;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showSnackBar('Layanan lokasi belum menyala bos.', isSuccess: false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showSnackBar('Akses lokasi ditolak.', isSuccess: false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSnackBar('Akses lokasi diblokir permanen.', isSuccess: false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationStatus = 'Lokasi Jitu 😎'; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _locationStatus = 'Error Lokasi: ${e.toString()}');
    }
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
      backgroundColor: isSuccess ? kSuccessColor : kErrorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(20),
      elevation: 8,
    ));
  }

  Future<void> _takePhoto() async {
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);
    if (absensiProvider.isLoading) return;

    final File? result = await Navigator.push<File>(context, MaterialPageRoute(builder: (_) => const CustomCameraScreen()));
    if (result != null && mounted) {
      await _checkLocation();
      setState(() {
        _capturedImageFile = result;
        _isPhotoTaken = true;
      });
      _showSnackBar('Cakep! Foto diterima.', isSuccess: true);
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImageFile = null;
      _isPhotoTaken = false;
    });
    _takePhoto();
  }
  
  Future<void> _submitAbsen() async {
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);

    if (absensiProvider.isLoading) return;
    
    if (_capturedImageFile == null || _currentPosition == null) {
      _showSnackBar('Foto selfie dan lokasi wajib dapet dulu.', isSuccess: false);
      return;
    }

    if (_isPulangSakit) {
      if (_fileBuktiSakit == null) {
         _showSnackBar('File bukti sakit wajib diupload.', isSuccess: false);
         return;
      }
      if (_keteranganSakitController.text.trim().isEmpty) {
         _showSnackBar('Keterangan sakit wajib diisi.', isSuccess: false);
         return;
      }
    }

    try {
      absensiProvider.setIsLoading(true);
      absensiProvider.setErrorMessage(null);
      await Future.delayed(const Duration(milliseconds: 600));

      final result = await absensiProvider.absenPulang(
        foto: _capturedImageFile!, lat: _currentPosition!.latitude, lng: _currentPosition!.longitude,
        tipe: _isPulangSakit ? 'sakit' : null, 
        keterangan: _isPulangSakit ? _keteranganSakitController.text.trim() : null,
        fileBukti: _isPulangSakit ? _fileBuktiSakit : null,
      );
      
      if (result['success'] == true && mounted) {
        _showSuccessDialog();
      } else {
        // Cek apakah ini error jaringan "bapuk"
        if (result['isNetworkError'] == true && mounted) {
          _showBapukDialog(result['message']);
        } else if (mounted) {
          int? statusCode = result['statusCode'];
          String? errorType = result['data'] != null ? result['data']['error_type'] : null;

          absensiProvider.setErrorMessage(result['message'] ?? 'Absensi Pulang Gagal.');
          
          if (statusCode == 403) {
             _showSnackBar('Absen Pulang Ditolak! Anda melanggar aturan jam keluar perusahaan hari ini.', isSuccess: false);
          } else if (statusCode == 400 && errorType == 'unfinished_izin') {
             _showSnackBar('Harap lampirkan bukti foto Izin Keluar terlebih dahulu untuk menyelesaikan sesi izin.', isSuccess: false);
          } else {
            String errorMsg = result['message']?.toLowerCase() ?? '';
            if (errorMsg.contains('jam') || errorMsg.contains('waktu') || errorMsg.contains('belum')) {
              _showRejectionDialog();
            } else {
              _showSnackBar(result['message'] ?? 'Gagal rek.', isSuccess: false);
            }
          }
        }
      }
    } catch (e) {
      absensiProvider.setErrorMessage('Terjadi error saat submit: ${e.toString()}');
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
                      backgroundColor: kErrorColor, padding: const EdgeInsets.symmetric(vertical: 16),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.beenhere_rounded, color: Colors.green.shade500, size: 60),
                ),
                const SizedBox(height: 20),
                const Text('Absensi Pulang Tercatat!', style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Waktu Pulang: ${DateFormat('HH:mm').format(DateTime.now())}', style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); 
                      Navigator.of(context).pop(); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0
                    ),
                    child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRejectionDialog() {
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
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                   child: Icon(Icons.access_time_filled_rounded, color: Colors.orange.shade500, size: 50),
                 ),
                 const SizedBox(height: 20),
                 const Text('Belum Waktunya Pulang!', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)), textAlign: TextAlign.center),
                 const SizedBox(height: 12),
                 const Text(
                   'Maaf, Anda tidak bisa absen karena belum memenuhi jam kerja yang ditentukan.\n\nSemangat terus ya para calon orang sukses! 💪✨', 
                   style: TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 13),
                   textAlign: TextAlign.center
                 ),
                 const SizedBox(height: 24),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: () => Navigator.of(context).pop(),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.grey.shade100, 
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       elevation: 0
                     ),
                     child: Text('Siap Bos!', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800)),
                   ),
                 ),
               ],
             ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final absensiProvider = Provider.of<AbsensiProvider>(context);
    final bool locationReady = _locationStatus.contains('Jitu') && _currentPosition != null;
    final Color headerColor = kErrorColor;
    
    final bool canSubmit = _isPhotoTaken && locationReady;
    final bool isButtonDisabled = absensiProvider.isLoading || !canSubmit;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Absensi Pulang', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF1F2937), fontWeight: FontWeight.w700, fontSize: 18)),
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [headerColor, headerColor.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: headerColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Text(_dateString, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(_timeString, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Roboto', fontSize: 50, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.grey.shade100, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Verifikasi Wajah (Selfie)', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 16),
                  
                  Container(
                    height: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: _isPhotoTaken ? Colors.transparent : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _isPhotoTaken ? Colors.transparent : Colors.grey.shade200, width: 2),
                    ),
                    child: _capturedImageFile != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_capturedImageFile!, fit: BoxFit.cover))
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.face_retouching_natural_rounded, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('Tap tombol di bawah untuk\nmembuka kamera selfie.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: locationReady ? Colors.green.shade50 : Colors.red.shade50, shape: BoxShape.circle),
                        child: Icon(locationReady ? Icons.my_location_rounded : Icons.location_off_rounded, color: locationReady ? Colors.green.shade500 : Colors.red.shade500, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(locationReady ? 'Lokasi Akurat' : 'Mencari Lokasi...', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: locationReady ? Colors.green.shade700 : Colors.red.shade700)),
                            if (!locationReady) Text(_locationStatus, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis, maxLines: 1),
                          ],
                        ),
                      ),
                      if (!locationReady && !absensiProvider.isLoading)
                         IconButton(onPressed: _checkLocation, icon: Icon(Icons.refresh_rounded, color: Colors.blue.shade600))
                      else if (!locationReady)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    ],
                  ),
                  const SizedBox(height: 24),

                  Container(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: absensiProvider.isLoading || !locationReady ? null : (_isPhotoTaken ? _retakePicture : _takePhoto),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: absensiProvider.isLoading || !locationReady ? Colors.grey.shade300 : kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isPhotoTaken ? Icons.replay_circle_filled_rounded : Icons.camera_alt_rounded, color: absensiProvider.isLoading || !locationReady ? Colors.grey.shade500 : Colors.white),
                          const SizedBox(width: 10),
                          Text(_isPhotoTaken ? 'ULANGI SELFIE' : 'BUKA KAMERA SELFIE', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: absensiProvider.isLoading || !locationReady ? Colors.grey.shade500 : Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // SAKIT TOGGLE SECTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.red.shade100, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                            child: Icon(Icons.local_hospital_rounded, color: Colors.red.shade500, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text('Pulang Lebih Awal (Sakit)', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                        ],
                      ),
                      Switch(
                        value: _isPulangSakit,
                        activeColor: Colors.red.shade500,
                        onChanged: (val) => setState(() => _isPulangSakit = val),
                      ),
                    ],
                  ),
                  
                  if (_isPulangSakit) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Keterangan / Alasan Sakit', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: kBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: TextFormField(
                        controller: _keteranganSakitController,
                        maxLines: 2,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Tulis gejala atau alasan sakit...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Dokumen / Surat Dokter', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickBuktiSakit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _fileBuktiSakit != null ? Colors.green.shade50 : Colors.blue.shade50,
                          border: Border.all(color: _fileBuktiSakit != null ? Colors.green.shade200 : Colors.blue.shade200, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(_fileBuktiSakit != null ? Icons.check_circle_rounded : Icons.upload_file_rounded, color: _fileBuktiSakit != null ? Colors.green.shade600 : Colors.blue.shade600, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_fileBuktiSakit != null ? 'Dokumen Terlampir' : 'Unggah File Bukti', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: _fileBuktiSakit != null ? Colors.green.shade700 : Colors.blue.shade700, fontSize: 13)),
                                  if (_fileBuktiSakit != null) 
                                    Text(_fileBuktiSakit!.path.split('/').last, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.green.shade600), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isButtonDisabled ? [] : [BoxShadow(color: kSuccessColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: ElevatedButton(
                onPressed: isButtonDisabled ? null : _submitAbsen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccessColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: absensiProvider.isLoading
                    ? const _ModernLoading(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.airplane_ticket_rounded, color: isButtonDisabled ? Colors.grey.shade500 : Colors.white),
                          const SizedBox(width: 8),
                          Text('KIRIM ABSENSI SEKARANG', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: isButtonDisabled ? Colors.grey.shade500 : Colors.white, letterSpacing: 0.5)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
