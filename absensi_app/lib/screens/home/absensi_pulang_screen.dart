import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async'; 
import '../../providers/absensi_provider.dart';
import 'package:intl/intl.dart';

// ======================================================================
// WIDGET BARU: BouncingDotsLoader (Tetap digunakan)
// ======================================================================
class BouncingDotsLoader extends StatefulWidget {
  const BouncingDotsLoader({super.key});

  @override
  State<BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<BouncingDotsLoader>
    with SingleTickerProviderStateMixin {
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
// MAIN SCREEN: AbsensiPulangScreen (Diperbarui)
// ======================================================================

class AbsensiPulangScreen extends StatefulWidget {
  final bool? lembur; 

  const AbsensiPulangScreen({super.key, this.lembur});

  @override
  State<AbsensiPulangScreen> createState() => _AbsensiPulangScreenState();
}

class _AbsensiPulangScreenState extends State<AbsensiPulangScreen> {
  final ImagePicker _picker = ImagePicker();
  
  // State Baru: Mengontrol alur
  File? _capturedImageFile;
  bool _isPhotoTaken = false; 
  Position? _currentPosition;
  final TextEditingController _keteranganController = TextEditingController(); // Controller untuk keterangan

  // State untuk Realtime Clock
  late String _timeString;
  late String _dateString;
  late Timer _timer;
  
  // Status Lokasi
  String _locationStatus = 'Memuat lokasi...';

  // Getter untuk menentukan tipe absensi untuk UI
  String get _tipeAbsensiUI {
    return widget.lembur == true ? 'Pulang Lembur' : 'Pulang Normal';
  }

  // Getter untuk menentukan tipe absensi untuk API/Provider
  // Nilai null akan digunakan untuk Pulang Normal
  String? get _tipeAbsensiAPI {
    return widget.lembur == true ? 'lembur' : null;
  }

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
    _keteranganController.dispose();
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
      // Pastikan lokasi diambil dan disimpan di _currentPosition
      final Position? position = await _getCurrentLocation();
      
      if (mounted) {
        if (position != null) {
          setState(() {
            _currentPosition = position;
            _locationStatus = 'Lokasi Terdeteksi';
          });
        } else {
          setState(() {
            _currentPosition = null;
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
          const SnackBar(content: Text('Izin lokasi ditolak permanen. Tidak dapat meminta izin.')),
        );
      }
      return null;
    }

    try {
      // Ambil posisi dan simpan di state
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Error Lokasi: ${e.toString()}';
        });
      }
      return null;
    }
  }

  // Method baru: Hanya mengambil foto dan update state
  Future<void> _takePhoto() async {
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);

    if (absensiProvider.isLoading) return;

    try {
      absensiProvider.setIsLoading(true); // Mulai loading untuk proses foto/lokasi
      absensiProvider.setErrorMessage(null);

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
        return;
      }
      
      // Ambil lokasi lagi untuk memastikan posisi terbaru
      await _checkLocation();

      setState(() {
        _capturedImageFile = File(capturedImage.path);
        // Pindah ke langkah berikutnya (form isian jika lembur)
        _isPhotoTaken = true; 
      });

    } catch (e) {
      absensiProvider.setErrorMessage('Gagal mengambil foto atau lokasi: ${e.toString()}');
    } finally {
      absensiProvider.setIsLoading(false);
    }
  }
  
  // Method baru: Mengirim data absen (dipanggil setelah foto dan form diisi)
  Future<void> _submitAbsen() async {
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);

    if (absensiProvider.isLoading) return;
    
    if (_capturedImageFile == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto dan lokasi wajib didapatkan sebelum submit.')),
      );
      return;
    }

    // Validasi keterangan jika mode lembur
    if (widget.lembur == true && _keteranganController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keterangan lembur wajib diisi.')),
      );
      return;
    }

    try {
      absensiProvider.setIsLoading(true);
      absensiProvider.setErrorMessage(null);

      final result = await absensiProvider.absenPulang(
        foto: _capturedImageFile!,
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        tipe: _tipeAbsensiAPI, 
        // Mengirimkan keterangan hanya jika mode lembur, jika tidak, mengirim null
        keterangan: widget.lembur == true ? _keteranganController.text.trim() : null,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Absensi $_tipeAbsensiUI berhasil!')),
          );
          Navigator.pop(context); 
        }
      } else {
        absensiProvider.setErrorMessage(result['message'] ?? 'Absensi Pulang Gagal.');
      }
    } catch (e) {
      absensiProvider.setErrorMessage('Terjadi error saat submit: ${e.toString()}');
    } finally {
      absensiProvider.setIsLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final absensiProvider = Provider.of<AbsensiProvider>(context);
    final bool locationDetected = _currentPosition != null;
    final bool isLembur = widget.lembur == true;
    
    final String buttonText = isLembur ? 'Absen Pulang Lembur' : 'Absen Pulang Normal';
    final Color buttonColor = isLembur ? Colors.orange.shade800 : Colors.red.shade600;

    // Teks Tombol Aksi Utama
    String mainActionButtonText = 'Ambil Foto Absen';
    if (_isPhotoTaken && isLembur) {
        mainActionButtonText = 'Ulangi Foto';
    } else if (_isPhotoTaken && !isLembur) {
        mainActionButtonText = 'Ulangi Foto';
    }


    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Absensi $_tipeAbsensiUI', style: const TextStyle(color: Colors.white)),
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
                
                // --- KONTEN FOTO (Langkah 1)
                Text(
                  'Langkah 1: Ambil Foto Absensi $_tipeAbsensiUI',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                
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
                            child: Image.file(_capturedImageFile!, fit: BoxFit.cover),
                          )
                      : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey),
                                SizedBox(height: 10),
                                Text(
                                  'Tekan tombol "Ambil Foto" di bawah.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                ),
                const SizedBox(height: 15),

                // Tombol Ambil Foto
                ElevatedButton.icon(
                  onPressed: absensiProvider.isLoading || !locationDetected ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(mainActionButtonText),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 25),


                // --- FORM KETERANGAN (Langkah 2 - Hanya untuk Lembur)
                if (_isPhotoTaken && isLembur)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 30, thickness: 1.5, color: Colors.orange),
                    Text(
                      'Langkah 2: Isi Keterangan Lembur',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _keteranganController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan Lembur (Wajib Diisi)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                      ),
                      enabled: !absensiProvider.isLoading,
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
                
                // --- LOKASI & SUBMIT (Langkah Akhir)
                const Divider(height: 30, thickness: 1.5, color: Colors.green),
                Text(
                    'Langkah Terakhir: Verifikasi Lokasi dan Submit',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                    ),
                ),
                const SizedBox(height: 15),

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
                
                // Tombol Submit Final
                ElevatedButton(
                  // Tombol hanya aktif jika Foto sudah diambil, Lokasi terdeteksi, DAN
                  // (Jika mode lembur, form keterangan sudah diisi ATAU Jika mode normal)
                  onPressed: (_isPhotoTaken && locationDetected && !absensiProvider.isLoading)
                      ? _submitAbsen
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: absensiProvider.isLoading || !_isPhotoTaken || !locationDetected ? Colors.grey : buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    elevation: 5,
                  ),
                  child: absensiProvider.isLoading
                      ? const BouncingDotsLoader()
                      : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.exit_to_app_rounded, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                isLembur ? 'SUBMIT ABSEN LEMBUR' : 'SUBMIT ABSEN PULANG',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                        ),
                ),
                const SizedBox(height: 10),
                
                // Error Message
                if (absensiProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      absensiProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}