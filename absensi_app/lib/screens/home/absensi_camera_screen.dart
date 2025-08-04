import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/absensi_provider.dart';
import 'package:intl/intl.dart';

class AbsensiCameraScreen extends StatefulWidget {
  const AbsensiCameraScreen({super.key});

  @override
  State<AbsensiCameraScreen> createState() => _AbsensiCameraScreenState();
}

class _AbsensiCameraScreenState extends State<AbsensiCameraScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Fungsi untuk mendapatkan lokasi, tidak ada perubahan
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
      // Mengambil foto dengan kompresi kualitas
      final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80, // <-- Tambahkan baris ini untuk kompresi
        maxWidth: 1024, // <-- Tambahkan ini untuk mengurangi resolusi (opsional)
      );

      if (capturedImage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengambilan foto dibatalkan.')),
          );
        }
        return;
      }

      final Position? position = await _getCurrentLocation();
      if (position == null) {
        return;
      }

      if (isAbsenMasuk) {
        String? statusAbsenMasuk = await showDialog<String>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Pilih Status Absen Masuk'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(title: const Text('Hadir'), onTap: () => Navigator.pop(dialogContext, 'hadir')),
                  ListTile(title: const Text('Sakit'), onTap: () => Navigator.pop(dialogContext, 'sakit')),
                  ListTile(title: const Text('Izin'), onTap: () => Navigator.pop(dialogContext, 'izin')),
                ],
              ),
            );
          },
        );
        if (statusAbsenMasuk == null) return;

        await absensiProvider.absenMasuk(
          foto: File(capturedImage.path),
          lat: position.latitude,
          lng: position.longitude,
          status: statusAbsenMasuk,
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
          foto: File(capturedImage.path),
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
              child: const Center(
                child: Text(
                  'Tekan tombol di bawah untuk absen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            absensiProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
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
                          title: Text('Waktu Masuk: ${DateFormat.Hm().format(DateTime.parse(absensiProvider.currentDayAbsensi!.checkInAt!))}'),
                        ),
                      if (absensiProvider.currentDayAbsensi!.checkOutAt != null)
                        ListTile(
                          leading: const Icon(Icons.access_time_filled, color: Colors.red),
                          title: Text('Waktu Pulang: ${DateFormat.Hm().format(DateTime.parse(absensiProvider.currentDayAbsensi!.checkOutAt!))}'),
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