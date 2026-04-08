// File: lib/screens/home/absensi_pulang_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'custom_camera_screen.dart';
import 'dart:io'; 
import 'dart:async'; 
import '../../providers/absensi_provider.dart'; 
import 'package:intl/intl.dart';

const Color kPrimaryColor = Color(0xFF152C5C); // Deep Corporate Blue
const Color kSecondaryColor = Color(0xFF3B82F6); // Bright Accent Blue (Untuk Aksi Utama)
const Color kSuccessColor = Color(0xFF10B981); // Emerald Green (Untuk Status Sukses)
const Color kErrorColor = Color(0xFFEF4444); // Red (Untuk Error)
const Color kLemburColor = Color(0xFFF97316); // Orange Terang (Untuk Mode Lembur)
const Color kBackgroundColor = Color(0xFFF0F4F8); // Light Ash Background

// ======================================================================
// WIDGET: BouncingDotsLoader (Diperbarui dengan kPrimaryColor)
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
// MAIN SCREEN: AbsensiPulangScreen
// ======================================================================

class AbsensiPulangScreen extends StatefulWidget {
  final bool? lembur; 

  const AbsensiPulangScreen({super.key, this.lembur});

  @override
  State<AbsensiPulangScreen> createState() => _AbsensiPulangScreenState();
}

class _AbsensiPulangScreenState extends State<AbsensiPulangScreen> {
  
  
  // State Utama
  File? _capturedImageFile;
  List<File> _hasilKerjaFiles = [];
  bool _isPhotoTaken = false; 
  Position? _currentPosition;
  
  // --- KONTROLER LEMBUR ---
  final TextEditingController _keteranganController = TextEditingController(); 
  final TextEditingController _goalsController = TextEditingController(); 
  final TextEditingController _jamMulaiController = TextEditingController(); 
  final TextEditingController _jamSelesaiController = TextEditingController(); 
  bool _istirahatChecked = false; 

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
    _goalsController.dispose();
    _jamMulaiController.dispose(); 
    _jamSelesaiController.dispose(); 
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

  // Method: Hanya mengambil foto dan update state
  Future<void> _takePhoto() async {
  final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);
  if (absensiProvider.isLoading) return;

  final File? result = await Navigator.push<File>(
    context,
    MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
  );

  if (result != null && mounted) {
    // Ambil lokasi terbaru setelah foto diambil
    await _checkLocation();

    setState(() {
      _capturedImageFile = result;
      _isPhotoTaken = true;
    });
  }
}

  Future<void> _pickHasilKerjaImages() async {
    final ImagePicker picker = ImagePicker();
    
    // Pick multiple images
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty && mounted) {
      // Cek limit maksimal 5
      if (pickedFiles.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maksimal 5 foto ya Bib!')),
        );
        return;
      }

      setState(() {
        _hasilKerjaFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();
      });
    }
  }

  // Fungsi untuk 'Ulangi Foto'
  void _retakePicture() {
    setState(() {
      _capturedImageFile = null;
      _isPhotoTaken = false;
    });
    // Panggil fungsi utama lagi untuk langsung membuka kamera
    _takePhoto();
  }
  
  // Method: Mengirim data absen
  Future<void> _submitAbsen() async {
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);

    if (widget.lembur == true && _hasilKerjaFiles.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wajib upload minimal 1 foto bukti kerja!'),
        backgroundColor: Colors.red,
      ),
    );
    return; // Berhenti di sini, jangan lanjut ke proses kirim API
  }
    if (absensiProvider.isLoading) return;
    
    // 1. Validasi Pra-Submit
    if (_capturedImageFile == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto dan lokasi wajib didapatkan sebelum submit.')),
      );
      return;
    }

    // Validasi tambahan jika mode lembur
    if (widget.lembur == true) {
      final isLemburFormValid = _keteranganController.text.trim().isNotEmpty &&
                                _jamMulaiController.text.trim().isNotEmpty &&
                                _jamSelesaiController.text.trim().isNotEmpty &&
                                _hasilKerjaFiles.isNotEmpty; 
                                
      if (!isLemburFormValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jam Mulai, Jam Selesai, dan Keterangan Lembur wajib diisi.')),
        );
        return;
      }
    }

    // 2. Submit Data
    try {
      absensiProvider.setIsLoading(true);
      absensiProvider.setErrorMessage(null);

      Map<String, dynamic> result;

      if (widget.lembur == true) {
        // PANGGIL ABSEN LEMBUR
        result = await absensiProvider.absenLembur(
          foto: _capturedImageFile!,
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
          jamMulai: _jamMulaiController.text.trim(), 
          jamSelesai: _jamSelesaiController.text.trim(),
          istirahat: _istirahatChecked,
          keterangan: _keteranganController.text.trim(),
          goals: _goalsController.text.trim(),
          hasilKerjaFiles: _hasilKerjaFiles,
        );
      } else {
        // PANGGIL ABSEN PULANG NORMAL
        result = await absensiProvider.absenPulang(
          foto: _capturedImageFile!,
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
          tipe: _tipeAbsensiAPI, 
          keterangan: null,
        );
      }
      
      if (result['success'] == true) {
        if (mounted) {
          _showSuccessDialog();
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
              const Icon(Icons.check_circle_outline, color: kSuccessColor, size: 60),
              const SizedBox(height: 15),
              Text(
                'Absensi $_tipeAbsensiUI Berhasil Dicatat!',
                style: const TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: kPrimaryColor
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Waktu Pulang: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
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

  // Widget Pembantu untuk Time Picker
  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor, 
              onPrimary: Colors.white, 
              surface: Colors.white, 
              onSurface: Colors.black,
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final now = DateTime.now();
      // Format 24 jam (HH:mm) agar mudah dikirim ke backend
      final formatted = DateFormat('HH:mm').format(
        DateTime(now.year, now.month, now.day, picked.hour, picked.minute),
      );
      setState(() {
        controller.text = formatted; 
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final absensiProvider = Provider.of<AbsensiProvider>(context);
    final bool locationReady = _locationStatus.contains('Terdeteksi') && _currentPosition != null;
    final bool isLembur = widget.lembur == true;
    final Color headerColor = isLembur ? kLemburColor : kErrorColor; // Merah untuk Pulang Normal, Oranye untuk Lembur

    // Logika Validasi Tombol Submit
    bool isLemburFormValid = true;
    if (isLembur && _isPhotoTaken) {
      isLemburFormValid = _keteranganController.text.trim().isNotEmpty &&
                          _goalsController.text.trim().isNotEmpty &&
                          _jamMulaiController.text.trim().isNotEmpty &&
                          _jamSelesaiController.text.trim().isNotEmpty &&
                          _hasilKerjaFiles.isNotEmpty;
    }
    
    final bool canSubmit = _isPhotoTaken && locationReady && isLemburFormValid;
    final bool isButtonDisabled = absensiProvider.isLoading || !canSubmit;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text('Absensi $_tipeAbsensiUI', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Digital Clock Card (Premium)
            _buildClockCard(),
            const SizedBox(height: 30),

            // 2. Foto & Lokasi Card (Fokus Utama)
            _buildActionCard(
              context, 
              absensiProvider, 
              locationReady, 
              headerColor
            ),

            // 3. Form Lembur (Hanya jika mode lembur dan foto sudah diambil)
            if (_isPhotoTaken && isLembur)
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: _buildLemburFormCard(absensiProvider),
              ),
            
            // 4. Tombol Submit Final
            const SizedBox(height: 30),
            _buildSubmitButton(absensiProvider, canSubmit, isButtonDisabled, headerColor),
            
            // Error Message
            if (absensiProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  absensiProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kErrorColor, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER UI MEWAH ---
  
  Widget _buildClockCard() {
    return Container(
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
              fontFamily: 'RobotoMono', 
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, 
    AbsensiProvider absensiProvider, 
    bool locationReady,
    Color headerColor,
  ) {
    return Container(
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
            'Verifikasi Pulang',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
          ),
          const Divider(height: 25, thickness: 1, color: Color(0xFFE0E0E0)),
          
          // Kotak Preview Gambar
          Container(
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: _isPhotoTaken ? Colors.black12 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isPhotoTaken ? headerColor : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: _capturedImageFile != null
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
                        Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text(
                          'Ambil foto untuk merekam waktu $_tipeAbsensiUI.',
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
            statusText: locationReady ? 'Lokasi Terdeteksi (Siap Foto)' : 'Status Lokasi: $_locationStatus',
            color: locationReady ? kSuccessColor : kErrorColor,
            onRefresh: absensiProvider.isLoading ? null : _checkLocation,
            isLoading: _locationStatus == 'Memuat lokasi...',
          ),
          const SizedBox(height: 25),


          // Tombol Ambil/Ulangi Foto
          ElevatedButton.icon(
            onPressed: absensiProvider.isLoading || !locationReady ? null : 
                     (_isPhotoTaken ? _retakePicture : _takePhoto),
            icon: Icon(_isPhotoTaken ? Icons.replay_circle_filled_rounded : Icons.camera_alt_rounded, size: 24),
            label: Text(_isPhotoTaken ? 'ULANGI FOTO' : 'AMBIL FOTO KEHADIRAN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: absensiProvider.isLoading || !locationReady ? Colors.grey : kSecondaryColor, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 8,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildLemburFormCard(AbsensiProvider absensiProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kLemburColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: kLemburColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_bottom, color: kLemburColor, size: 24),
              SizedBox(width: 10),
              Text(
                'Detail Lembur (Wajib Diisi)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kLemburColor),
              ),
            ],
          ),
          const Divider(height: 25, thickness: 1, color: Color(0xFFFEEBCF)),

          // Input Jam
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _jamMulaiController,
                  readOnly: true, 
                  decoration: _buildInputDecoration('Jam Mulai', kLemburColor, Icons.access_time_filled),
                  onTap: () => _selectTime(_jamMulaiController),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextFormField(
                  controller: _jamSelesaiController,
                  readOnly: true, 
                  decoration: _buildInputDecoration('Jam Selesai', kLemburColor, Icons.access_time_filled),
                  onTap: () => _selectTime(_jamSelesaiController),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Checkbox Istirahat
          InkWell(
            onTap: absensiProvider.isLoading ? null : () {
              setState(() {
                _istirahatChecked = !_istirahatChecked;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Checkbox(
                    value: _istirahatChecked,
                    onChanged: absensiProvider.isLoading ? null : (bool? value) {
                      setState(() {
                        _istirahatChecked = value ?? false;
                      });
                    },
                    activeColor: kLemburColor,
                  ),
                  const Text('Ambil istirahat (Istirahat Dihitung)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          
          // Keterangan
          TextFormField(
            controller: _keteranganController,
            maxLines: 4,
            decoration: _buildInputDecoration('Jelasin Lu lembur apaan', kLemburColor),
            enabled: !absensiProvider.isLoading,
          ),

          const SizedBox(height: 15),

          // Goals Pekerjaan
          TextFormField(
            controller: _goalsController,
            maxLines: 2,
            decoration: _buildInputDecoration('Goals lembur (contoh: packing parfum 1000 botol)', kLemburColor),
            enabled: !absensiProvider.isLoading,
          ),

          // ✅ TAMBAH MULAI DARI SINI SAMPAI BAWAH (Setelah TextFormField Keterangan)
          const SizedBox(height: 20),
          const Text(
            'Upload Bukti Kerja (Minimal 1, Maksimal 5)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 10),
          
          InkWell(
            onTap: _pickHasilKerjaImages, // Panggil fungsi galeri tadi
            child: Container(
              constraints: const BoxConstraints(minHeight: 100),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hasilKerjaFiles.isNotEmpty ? Colors.green : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: _hasilKerjaFiles.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.drive_folder_upload, size: 40, color: Colors.grey.shade400),
                        const Text('Pilih Foto dari Galeri', style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, 
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _hasilKerjaFiles.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_hasilKerjaFiles[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _hasilKerjaFiles.removeAt(index));
                                },
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),

        ],
      ),    );         
}

  InputDecoration _buildInputDecoration(String label, Color color, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: color.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: color, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: color.withOpacity(0.5)),
      ),
      suffixIcon: icon != null ? Icon(icon, color: color) : null,
      labelStyle: TextStyle(color: color),
    );
  }
  
  Widget _buildSubmitButton(
    AbsensiProvider absensiProvider, 
    bool canSubmit, 
    bool isButtonDisabled, 
    Color buttonColor
  ) {
    return ElevatedButton(
      onPressed: isButtonDisabled ? null : _submitAbsen,
      style: ElevatedButton.styleFrom(
        backgroundColor: isButtonDisabled ? Colors.grey : buttonColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        elevation: 8,
      ),
      child: absensiProvider.isLoading
          ? const BouncingDotsLoader(dotColor: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.exit_to_app_rounded, size: 24),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.lembur == true ? 'SUBMIT ABSEN LEMBUR' : 'SUBMIT ABSEN PULANG',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
  
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
              child: const Icon(Icons.refresh, color: kSecondaryColor, size: 22),
            ),
          )
      ],
    );
  }
}
