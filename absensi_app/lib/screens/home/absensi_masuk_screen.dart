// File: lib/screens/home/absensi_masuk_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; 
import 'dart:async'; // Untuk jam realtime dan timer
import '../../providers/absensi_provider.dart'; 
import 'package:intl/intl.dart';

// ======================================================================
// WIDGET BARU: BouncingDotsLoader (Indicator Loading)
// ======================================================================
class BouncingDotsLoader extends StatefulWidget {
  const BouncingDotsLoader({super.key});

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
        decoration: const BoxDecoration(
          color: Colors.white, 
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

  @override
  void initState() {
    super.initState();
    // Set locale ke Bahasa Indonesia untuk format tanggal
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

  // Fungsi untuk mendapatkan dan memverifikasi lokasi
  Future<void> _checkLocation() async {
      final Position? position = await _getCurrentLocation();
      
      if (position != null) {
        setState(() {
          // Tampilkan hanya pesan status utama di UI
          _locationStatus = 'Lokasi Terdeteksi'; 
        });
      } else {
        setState(() {
          _locationStatus = 'Gagal Mendeteksi Lokasi';
        });
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
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Error Lokasi';
        });
      }
      return null;
    }
  }

  Future<void> _takePictureAndAbsenMasuk() async {
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);
    if (absensiProvider.isLoading) return;

    // 1. Ambil Foto
    try {
      absensiProvider.setIsLoading(true); 
      
      final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70, 
        maxWidth: 800,
      );

      if (capturedImage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengambilan foto dibatalkan.')),
          );
        }
        absensiProvider.setIsLoading(false);
        return;
      }

      setState(() {
        _capturedImageFile = File(capturedImage.path);
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka kamera: ${e.toString()}')),
        );
      }
      absensiProvider.setIsLoading(false);
      return;
    }

    // 2. Ambil Lokasi
    final Position? position = await _getCurrentLocation();
    if (position == null) {
      absensiProvider.setIsLoading(false);
      return;
    }
    
    // 3. Kirim Absensi
    try {
      await absensiProvider.absenMasuk(
        foto: _capturedImageFile!,
        lat: position.latitude,
        lng: position.longitude,
        status: 'hadir',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absensi masuk berhasil!')),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Absensi gagal: ${e.toString()}')),
        );
      }
    } finally {
      absensiProvider.setIsLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final absensiProvider = Provider.of<AbsensiProvider>(context);
    final bool locationDetected = _locationStatus.contains('Terdeteksi');

    return Scaffold(
      backgroundColor: Colors.grey[200], 
      appBar: AppBar(
        title: const Text('Absensi Masuk', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF003366), 
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Waktu dan Tanggal
                Text(
                  _dateString,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _timeString,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40, 
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF003366),
                  ),
                ),
                const Divider(height: 30, thickness: 1.5, color: Colors.blueAccent),
                
                // Judul Foto
                const Text(
                  'Ambil Foto Kehadiran',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                
                // Kotak Preview Gambar
                Container(
                  height: MediaQuery.of(context).size.width * 0.75,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _capturedImageFile != null ? Colors.green : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: _capturedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            _capturedImageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                'Tekan tombol di bawah untuk membuka kamera depan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 25),
                
                // Status Lokasi
                Row(
                  children: [
                    Icon(
                      locationDetected ? Icons.location_on : Icons.location_off,
                      color: locationDetected ? Colors.green : Colors.red, 
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationStatus,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: locationDetected ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.blueGrey),
                      onPressed: absensiProvider.isLoading ? null : _checkLocation,
                    )
                  ],
                ),
                const SizedBox(height: 25),
                
                // Tombol Absen
                ElevatedButton(
                  onPressed: absensiProvider.isLoading || !locationDetected ? null : _takePictureAndAbsenMasuk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: absensiProvider.isLoading || !locationDetected ? Colors.grey : Colors.green.shade600, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    elevation: 5,
                  ),
                  child: absensiProvider.isLoading
                      ? const BouncingDotsLoader()
                      // START PERBAIKAN OVERFLOW DI SINI
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 24),
                            SizedBox(width: 5),
                            // Membungkus Text dengan Expanded agar teks menyesuaikan lebar yang tersedia
                            Expanded( 
                              child: Text(
                                'Absen Masuk Sekarang',
                                textAlign: TextAlign.center, // Agar teks tetap di tengah area Expanded
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      // END PERBAIKAN
                ),
                const SizedBox(height: 10),
                Text(
                  locationDetected ? 'Pastikan foto dan lokasi sudah benar sebelum absen.' : 'Tidak dapat absen. Lokasi belum terdeteksi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: locationDetected ? Colors.grey : Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}