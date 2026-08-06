import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class UpdateService {
  // URL JSON versi
  static const String _updateUrl = 'https://absensi.anselmudaberkarya.my.id/update.json';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(_updateUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestVersion = data['version'];
        String downloadUrl = data['download_url'];

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;

        if (_isNewerVersion(latestVersion, currentVersion)) {
          _showUpdateDialog(context, latestVersion, downloadUrl);
        }
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    try {
      List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
    } catch (e) {
      return latest != current;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String version, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(Icons.system_update_rounded, size: 50, color: Colors.indigo),
        title: Text(
          'Pembaruan Tersedia',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Versi v$version sudah rilis!',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo),
            ),
            const SizedBox(height: 12),
            const Text(
              'Update sekarang untuk mendapatkan fitur terbaru dan performa yang lebih stabil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Nanti Saja', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              _startUpdate(context, url);
            },
            child: const Text('Update Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void _startUpdate(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateDialogContent(url: url),
    );
  }
}

class _UpdateDialogContent extends StatefulWidget {
  final String url;
  const _UpdateDialogContent({required this.url});

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  double _progress = 0;
  String _status = "Menghubungkan...";
  bool _isError = false;
  bool _showManualButton = false;
  StreamSubscription? _subscription;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initDownload();
    
    // Tampilkan tombol manual setelah 15 detik jika masih menghubungkan
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _progress == 0 && !_isError) {
        setState(() {
          _showManualButton = true;
          _status = "Koneksi lambat, coba download manual?";
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _initDownload() {
    try {
      debugPrint('🚀 [OTA] Memulai unduhan dari: ${widget.url}');
      
      _subscription = OtaUpdate().execute(
        widget.url,
        // Hapus destinationFilename agar plugin menentukan path yang paling aman/valid secara otomatis
      ).listen(
        (OtaEvent event) {
          if (!mounted) return;
          
          setState(() {
            if (event.value != null && event.value!.isNotEmpty) {
              _progress = double.tryParse(event.value!) ?? 0;
            }

            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _status = "Mengunduh file... ${_progress.toInt()}%";
                _showManualButton = false;
                break;
              case OtaStatus.INSTALLING:
                _status = "Membuka installer... Silakan ikuti petunjuk di layar.";
                // Jangan pop Navigator di sini, biarkan OS yang menghandle transisi ke installer
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                _status = "Izin instalasi ditolak. Berikan izin instalasi aplikasi tidak dikenal.";
                _isError = true;
                _showManualButton = true;
                break;
              case OtaStatus.INTERNAL_ERROR:
                _status = "Gagal memproses file (Internal Error).";
                _isError = true;
                _showManualButton = true;
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                _status = "Pembaruan sedang berjalan di latar belakang.";
                break;
              case OtaStatus.CHECKSUM_ERROR:
                _status = "Verifikasi file gagal (Checksum Error).";
                _isError = true;
                _showManualButton = true;
                break;
              default:
                _status = "Menyiapkan sistem pembaruan...";
            }
          });
        },
        onError: (e) {
          debugPrint('❌ [OTA] Error Listen: $e');
          if (mounted) {
            setState(() {
              _status = "Gagal: Sistem installer bermasalah.";
              _isError = true;
              _showManualButton = true;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('❌ [OTA] Exception Catch: $e');
      if (mounted) {
        setState(() { 
          _status = "Gagal memulai sistem: $e"; 
          _isError = true; 
          _showManualButton = true;
        });
      }
    }
  }

  Future<void> _launchManualDownload() async {
    final Uri url = Uri.parse(widget.url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka browser.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isError && !_showManualButton)
              const SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  color: Colors.indigo,
                ),
              )
            else
              const Icon(Icons.info_outline_rounded, size: 60, color: Colors.orange),
              
            const SizedBox(height: 30),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              _isError ? 'Gunakan tombol di bawah untuk download manual.' : 'Jangan tutup aplikasi sampai proses selesai',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            
            if (!_isError)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 12,
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  color: Colors.indigo,
                ),
              ),
              
            if (_showManualButton || _isError)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: _launchManualDownload,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Download Manual (Chrome)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_isError ? 'Tutup' : 'Batal', style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }
}
