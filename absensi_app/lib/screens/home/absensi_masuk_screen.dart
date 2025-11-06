// File: lib/screens/home/absensi_masuk_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; 
import 'dart:async'; 
import '../../providers/absensi_provider.dart'; 
import 'package:intl/intl.dart';

// --- Definisi Warna Korporat Premium ---
const Color kPrimaryColor = Color(0xFF152C5C); // Deep Corporate Blue
const Color kSecondaryColor = Color(0xFF3B82F6); // Bright Accent Blue
const Color kSuccessColor = Color(0xFF10B981); // Emerald Green
const Color kErrorColor = Color(0xFFEF4444); // Red
const Color kBackgroundColor = Color(0xFFF0F4F8); // Light Ash Background

// ======================================================================
// WIDGET: BouncingDotsLoader
// ======================================================================
class BouncingDotsLoader extends StatefulWidget {
  final Color dotColor;
  const BouncingDotsLoader({super.key, this.dotColor = Colors.white});

  @override
  State<BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<BouncingDotsLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.bounceOut),
      ),
    );

    _animation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.bounceOut),
      ),
    );

    _animation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.bounceOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(Animation<double> animation) {
    return ScaleTransition(
      scale: animation,
      child: Container(
        width: 12.0,
        height: 12.0,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: widget.dotColor, 
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildDot(_animation1),
        _buildDot(_animation2),
        _buildDot(_animation3),
      ],
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
  final ImagePicker _picker = ImagePicker();
  File? _capturedImageFile; 

  // State untuk Realtime Clock
  late String _timeString;
  late String _dateString;
  late Timer _timer;
  
  // Status Lokasi
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
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  void _updateTime() {
    if (mounted) {
      setState(() {
        _timeString = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  Future<void> _checkLocation() async {
    setState(() {
      _locationStatus = 'Memuat lokasi...';
      _currentPosition = null;
    });

    final Position? position = await _getCurrentLocation();
    
    if (mounted) {
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _locationStatus = 'Lokasi Terdeteksi'; 
        });
      } else {
        setState(() {
          _locationStatus = 'Gagal Mendeteksi Lokasi';
        });
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan lokasi tidak diaktifkan. Mohon aktifkan.')),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak.')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak secara permanen. Tidak dapat meminta izin.')),
        );
      }
      return null;
    }

    try {
      // Tambahkan timeout untuk mencegah loading tak terbatas
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Error Lokasi: ${e.toString()}';
        });
      }
      return null;
    }
  }


  // ✨ LOGIKA UTAMA TOMBOL (Ambil Foto/Kirim Absensi)
  Future<void> _handleAbsensiAction() async {
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);
    if (absensiProvider.isLoading) return;

    // A. JIKA BELUM ADA FOTO -> Ambil Foto (Tahap 1)
    if (_capturedImageFile == null) {
      await _takePicture(absensiProvider);
    } 
    
    // B. JIKA SUDAH ADA FOTO -> Kirim Absensi (Tahap 2)
    else {
      await _submitAbsenMasuk(absensiProvider);
    }
  }

  Future<void> _takePicture(AbsensiProvider provider) async {
    try {
      provider.setIsLoading(true); 
      
      final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70, 
        maxWidth: 800,
      );

      if (capturedImage != null) {
        if (mounted) {
          setState(() {
            _capturedImageFile = File(capturedImage.path);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto berhasil diambil. Silakan kirim absensi.'),
              backgroundColor: kSecondaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka kamera: ${e.toString()}')),
        );
      }
    } finally {
      provider.setIsLoading(false);
    }
  }
  
  Future<void> _submitAbsenMasuk(AbsensiProvider provider) async {
    // 1. Validasi Lokasi
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi belum terdeteksi. Silakan refresh lokasi dan coba lagi.')),
      );
      await _checkLocation();
      return;
    }

    // 2. Kirim Data
    provider.setIsLoading(true);
    try {
      await provider.absenMasuk(
        foto: _capturedImageFile!,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        status: 'hadir',
      );
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Absensi gagal: ${e.toString()}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } finally {
      provider.setIsLoading(false);
    }
  }

  // ✨ Modal Sukses Canggih
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: kSuccessColor, size: 60),
              const SizedBox(height: 15),
              const Text(
                'Absensi Berhasil Dicatat!',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: kPrimaryColor
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Waktu Masuk: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Kembali ke halaman utama/sebelumnya
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  elevation: 5,
                ),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi untuk 'Ulangi Foto'
  void _retakePicture() {
    setState(() {
      _capturedImageFile = null;
    });
    // Panggil fungsi utama lagi untuk langsung membuka kamera
    _handleAbsensiAction();
  }


  @override
  Widget build(BuildContext context) {
    final absensiProvider = Provider.of<AbsensiProvider>(context);
    final bool locationReady = _locationStatus.contains('Terdeteksi') && _currentPosition != null;
    final bool hasImage = _capturedImageFile != null;
    
    // Konfigurasi Tombol Utama
    final String buttonLabel = hasImage ? 'KIRIM ABSENSI SEKARANG' : 'AMBIL FOTO KEHADIRAN';
    final Color buttonColor = hasImage ? kSuccessColor : kSecondaryColor;
    final IconData buttonIcon = hasImage ? Icons.send_rounded : Icons.camera_alt_rounded;
    // Tombol non-aktif jika sedang loading, atau jika mau kirim tapi lokasi belum siap
    final bool isButtonDisabled = absensiProvider.isLoading || (hasImage && !locationReady);


    return Scaffold(
      backgroundColor: kBackgroundColor, 
      appBar: AppBar(
        title: const Text('Absensi Masuk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: kPrimaryColor, 
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Digital Clock Card (Lebih Canggih)
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _dateString,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _timeString,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 55, 
                      fontFamily: 'RobotoMono', // Gunakan font yang terlihat seperti jam digital
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            
            // 2. Foto & Lokasi Card (Fokus Utama)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Verifikasi Kehadiran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
                  ),
                  const Divider(height: 25, thickness: 1, color: Color(0xFFE0E0E0)),
                  
                  // Kotak Preview Gambar
                  Container(
                    height: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                      color: hasImage ? Colors.black12 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasImage ? kSuccessColor : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _capturedImageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_pin_circle_outlined, size: 50, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                Text(
                                  'Wajah Anda harus terlihat jelas untuk validasi.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Status Lokasi & Refresh
                  _buildStatusRow(
                    icon: locationReady ? Icons.my_location : Icons.location_off,
                    statusText: locationReady ? 'Lokasi Valid (Siap Kirim)' : 'Status Lokasi: $_locationStatus',
                    color: locationReady ? kSuccessColor : kErrorColor,
                    onRefresh: absensiProvider.isLoading ? null : _checkLocation,
                    isLoading: _locationStatus == 'Memuat lokasi...',
                  ),
                  const SizedBox(height: 25),


                  // Tombol Aksi Utama
                  ElevatedButton(
                    onPressed: isButtonDisabled ? null : _handleAbsensiAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isButtonDisabled ? Colors.grey : buttonColor, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 8,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                    ),
                    child: absensiProvider.isLoading
                        ? BouncingDotsLoader(dotColor: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(buttonIcon, size: 24),
                              const SizedBox(width: 10),
                              Text(buttonLabel),
                            ],
                          ),
                  ),
                  
                  // Tombol Ulangi Foto (Jika sudah ada foto)
                  if (hasImage && !absensiProvider.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: TextButton(
                        onPressed: _retakePicture,
                        child: Text(
                          'Ulangi Foto',
                          style: TextStyle(color: kSecondaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Pembantu untuk Status Lokasi
  Widget _buildStatusRow({
    required IconData icon,
    required String statusText,
    required Color color,
    VoidCallback? onRefresh,
    required bool isLoading,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2, color: kSecondaryColor),
            ),
          )
        else if (onRefresh != null)
          InkWell(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.all(5),
              child: Icon(Icons.refresh, color: kSecondaryColor, size: 22),
            ),
          )
      ],
    );
  }
}