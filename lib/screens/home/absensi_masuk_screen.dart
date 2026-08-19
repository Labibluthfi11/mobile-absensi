import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/app_colors.dart';
import 'custom_camera_screen.dart';
import 'absensi_lembur_screen.dart';
import 'package:universal_io/io.dart'; 
import 'dart:async'; 
import 'dart:math' as math;
import '../../providers/absensi_provider.dart'; 
import 'package:intl/intl.dart';
import '../../services/security_service.dart';

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

// ======================================================================
// MAIN SCREEN: AbsensiMasukScreen
// ======================================================================
class AbsensiMasukScreen extends StatefulWidget {
  const AbsensiMasukScreen({super.key});

  @override
  State<AbsensiMasukScreen> createState() => _AbsensiMasukScreenState();
}

class _AbsensiMasukScreenState extends State<AbsensiMasukScreen> {
  File? _capturedImageFile; 

  late String _timeString;
  late String _dateString;
  late Timer _timer;
  
  String _locationStatus = 'Memuat lokasi...';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID'; 
    _timeString = DateFormat('HH:mm:ss').format(DateTime.now());
    _dateString = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    _checkLocation();
    
    // Refresh data absensi biar validasi absen dobel akurat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AbsensiProvider>(context, listen: false).fetchHistoryAbsensi();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  void _updateTime() {
    if (mounted) setState(() => _timeString = DateFormat('HH:mm:ss').format(DateTime.now()));
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
        if (mounted) _showSnackBar('Kamu nolak akses lokasi ya?', isSuccess: false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSnackBar('Akses lokasi diblokir permanen bos.', isSuccess: false);
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
      if (mounted) {
        setState(() => _locationStatus = 'Aduh Gagal: ${e.toString()}');
      }
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
      backgroundColor: isSuccess ? AppColors.kSuccessColor : AppColors.kErrorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(20),
      elevation: 8,
    ));
  }

  Future<void> _handleAbsensiAction() async {
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);
    if (absensiProvider.isLoading) return;

    // Premium Haptic Feedback
    HapticFeedback.mediumImpact();

    if (_capturedImageFile == null) {
      await _takePicture(absensiProvider);
    } else {
      await _submitAbsenMasuk(absensiProvider);
    }
  }

  Future<void> _takePicture(AbsensiProvider provider) async {
    final File? result = await Navigator.push<File>(context, MaterialPageRoute(builder: (_) => const CustomCameraScreen()));
    if (result != null && mounted) {
      setState(() => _capturedImageFile = result);
      _showSnackBar('Cakep! Sekarang gaskeuuun kirim absensi.', isSuccess: true);
    }
  }
  
  Future<void> _submitAbsenMasuk(AbsensiProvider provider) async {
    if (provider.currentDayAbsensi != null) {
      _showFunnyWarningDialog();
      return;
    }

    if (_currentPosition == null) {
      _showSnackBar('Lokasi blm ke-detect bro. Refresh dulu mending.', isSuccess: false);
      return;
    }

    // 🔥 SECURITY CHECK: Deteksi Mock Location / Fake GPS
    bool isMock = await SecurityService.isMockLocation();
    if (isMock || (_currentPosition != null && _currentPosition!.isMocked)) {
      _showSnackBar('Hayo loh! Matiin Fake GPS nya dulu bos, jangan curang!', isSuccess: false);
      return;
    }

    // Set loading state IMMEDIATELY at the start of submission
    provider.setIsLoading(true);
    try {
      await Future.delayed(const Duration(milliseconds: 600)); // smooth ux delay
      final result = await provider.absenMasuk(
        foto: _capturedImageFile!,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        status: 'hadir',
      );
      
      if (mounted) {
        if (result['success'] == true) {
          _showSuccessDialog();
        } else {
          // Cek status code 403 (Hari Libur)
          if (result['statusCode'] == 403) {
            _showHolidayDialog(result['message'] ?? 'Hari ini adalah hari libur.');
          }
          // Cek apakah ini error jaringan "bapuk"
          else if (result['isNetworkError'] == true) {
            _showBapukDialog(result['message']);
          } else {
            _showSnackBar(result['message'] ?? 'Duh, absen gagal rek.', isSuccess: false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Terjadi kesalahan fatal: ${e.toString()}', isSuccess: false);
      }
    } finally {
      if (mounted) provider.setIsLoading(false);
    }
  }

  void _showFunnyWarningDialog() {
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
                  decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade500, size: 60),
                ),
                const SizedBox(height: 20),
                const Text('Waduh!', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text('bro berpikir dia siapa mau absen dua kali mikir kids!!', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade500, padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0
                    ),
                    child: const Text('Oke Oke.. Ampun', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHolidayDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.calendar_today_rounded, color: Colors.amber.shade600, size: 60),
                ),
                const SizedBox(height: 20),
                const Text('Hari Libur Terdeteksi', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(message, style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => AbsensiLemburScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kLemburColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0
                        ),
                        child: const Text('Buka Menu Lembur', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
                      backgroundColor: AppColors.kErrorColor, padding: const EdgeInsets.symmetric(vertical: 16),
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
                const Text('Hadir Tercatat!', style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Waktu Masuk: ${DateFormat('HH:mm').format(DateTime.now())}', style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); 
                      Navigator.of(context).pop(); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 16),
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

  void _retakePicture() {
    setState(() => _capturedImageFile = null);
    _handleAbsensiAction();
  }

  @override
  Widget build(BuildContext context) {
    final absensiProvider = Provider.of<AbsensiProvider>(context);
    final bool locationReady = _locationStatus.contains('Jitu') && _currentPosition != null;
    final bool hasImage = _capturedImageFile != null;
    
    final String buttonLabel = hasImage ? 'KIRIM ABSENSI' : 'BUKA KAMERA';
    final Color buttonColor = hasImage ? AppColors.kSuccessColor : AppColors.kPrimaryColor;
    final bool isButtonDisabled = absensiProvider.isLoading || (hasImage && !locationReady);

    return PopScope(
      canPop: !absensiProvider.isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sedang mengunggah absensi, harap tunggu...')),
        );
      },
      child: Scaffold(
      backgroundColor: AppColors.kBackgroundColor, 
      appBar: AppBar(
        title: const Text('Absensi Masuk', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF1F2937), fontWeight: FontWeight.w700, fontSize: 18)),
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
            // Live Clock Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.kPrimaryColor, AppColors.kAccentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: AppColors.kPrimaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
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
            
            // Interaction Card
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
                      color: hasImage ? Colors.transparent : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: hasImage ? Colors.transparent : Colors.grey.shade200, width: 2),
                    ),
                    child: hasImage
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
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isButtonDisabled ? [] : [BoxShadow(color: buttonColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
                    ),
                    child: ElevatedButton(
                      onPressed: isButtonDisabled ? null : _handleAbsensiAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: absensiProvider.isLoading
                          ? const _ModernLoading(color: Colors.white)
                          : Text(buttonLabel, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                    ),
                  ),
                  
                  if (hasImage && !absensiProvider.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: GestureDetector(
                        onTap: _retakePicture,
                        child: const Center(child: Text('Ulangi Foto', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13, decoration: TextDecoration.underline))),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}