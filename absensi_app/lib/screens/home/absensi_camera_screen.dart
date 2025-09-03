import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/absensi_provider.dart';
import 'package:intl/intl.dart';

// Widget baru untuk animasi loading dengan 3 titik memantul
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
        decoration: BoxDecoration(
          color: Colors.blueAccent,
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

class AbsensiCameraScreen extends StatefulWidget {
  const AbsensiCameraScreen({super.key});

  @override
  State<AbsensiCameraScreen> createState() => _AbsensiCameraScreenState();
}

class _AbsensiCameraScreenState extends State<AbsensiCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedImageFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _takePictureAndProcessAbsensi({required bool isAbsenMasuk}) async {
    final absensiProvider = Provider.of<AbsensiProvider>(context, listen: false);

    if (absensiProvider.isLoading) return;

    absensiProvider.setIsLoading(true);

    try {
      final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
        maxWidth: 1024,
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

      if (_capturedImageFile == null || !_capturedImageFile!.existsSync() || _capturedImageFile!.lengthSync() == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengambil foto. Silakan coba lagi.')),
          );
        }
        absensiProvider.setIsLoading(false);
        return;
      }

      final Position? position = await _getCurrentLocation();
      if (position == null) {
        absensiProvider.setIsLoading(false);
        return;
      }

      if (isAbsenMasuk) {
        await absensiProvider.absenMasuk(
          foto: _capturedImageFile!,
          lat: position.latitude,
          lng: position.longitude,
          status: 'hadir', // Langsung set status menjadi 'hadir'
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Absensi masuk berhasil!')),
          );
        }
      } else {
        String? tipePulang = await showDialog<String>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Pilih Tipe Absen Pulang'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(title: const Text('Tidak Lembur'), onTap: () => Navigator.pop(dialogContext, null)),
                  ListTile(title: const Text('Lembur'), onTap: () => Navigator.pop(dialogContext, 'lembur')),
                ],
              ),
            );
          },
        );

        await absensiProvider.absenPulang(
          foto: _capturedImageFile!,
          lat: position.latitude,
          lng: position.longitude,
          tipe: tipePulang,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Absensi pulang berhasil!')),
          );
        }
      }
    } catch (e) {
      print('Absen error: $e');
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Absensi Hari Ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: _capturedImageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _capturedImageFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Tekan tombol di bawah untuk absen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            absensiProvider.isLoading
                ? const BouncingDotsLoader() // <-- Widget loading baru di sini
                : Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: absensiProvider.currentDayAbsensi == null
                            ? () => _takePictureAndProcessAbsensi(isAbsenMasuk: true)
                            : null,
                        icon: const Icon(Icons.arrow_circle_right),
                        label: const Text('Absen Masuk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: absensiProvider.currentDayAbsensi != null &&
                                absensiProvider.currentDayAbsensi!.checkOutAt == null
                            ? () => _takePictureAndProcessAbsensi(isAbsenMasuk: false)
                            : null,
                        icon: const Icon(Icons.arrow_circle_left),
                        label: const Text('Absen Pulang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            if (absensiProvider.currentDayAbsensi != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status Absensi Hari Ini:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 16, thickness: 1),
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                        title: Text('Status: ${absensiProvider.currentDayAbsensi!.status}'),
                      ),
                      if (absensiProvider.currentDayAbsensi!.checkInAt != null)
                        ListTile(
                          leading: const Icon(Icons.access_time, color: Colors.blue),
                          title: Text('Waktu Masuk: ${DateFormat.Hm().format(DateTime.parse(absensiProvider.currentDayAbsensi!.checkInAt!).toLocal())}'),
                        ),
                      if (absensiProvider.currentDayAbsensi!.checkOutAt != null)
                        ListTile(
                          leading: const Icon(Icons.access_time_filled, color: Colors.red),
                          title: Text('Waktu Pulang: ${DateFormat.Hm().format(DateTime.parse(absensiProvider.currentDayAbsensi!.checkOutAt!).toLocal())}'),
                        ),
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
