import 'package:flutter/material.dart';
import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'package:absensi_app/services/image_compress_service.dart';
import 'package:universal_io/io.dart';

class AbsensiProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Absensi> _myAbsensiList = [];
  Absensi? _currentDayAbsensi;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialLoadComplete = false;

  // Statistik
  int _totalHadir = 0;
  int _totalIzin = 0;
  int _totalSakit = 0;
  int _totalTelat = 0;
  int _totalLembur = 0;
  int _totalTanpaKet = 0;
  double _uploadProgress = 0;

  // Getters
  List<Absensi> get myAbsensiList => _myAbsensiList;
  Absensi? get currentDayAbsensi => _currentDayAbsensi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialLoadComplete => _isInitialLoadComplete;
  double get uploadProgress => _uploadProgress;

  int get totalHadir => _totalHadir;
  int get totalIzin => _totalIzin;
  int get totalSakit => _totalSakit;
  int get totalTelat => _totalTelat;
  int get totalLembur => _totalLembur;
  int get totalTanpaKet => _totalTanpaKet;

  AbsensiProvider({required ApiService apiService}) 
    : _apiService = apiService {
    refreshAbsensi();
  }

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> refreshAbsensi() async {
    _myAbsensiList = [];
    _currentDayAbsensi = null;
    _errorMessage = null;
    _isInitialLoadComplete = false;
    notifyListeners();
    await fetchHistoryAbsensi();
  }

  // ✅ UPDATE: Tambahkan parameter optional untuk filter & default ke bulan/tahun sekarang jika kosong
  Future<void> fetchHistoryAbsensi({String? searchDate, int? month, int? year, bool silent = false}) async {
    if (!silent) setIsLoading(true);
    _errorMessage = null;

    // 🔥 FIX: Jika dipanggil tanpa parameter (misal saat refresh awal), 
    // pastikan month & year masuk agar server tidak log URL kosongan.
    final now = DateTime.now();
    int? effectiveMonth = month;
    int? effectiveYear = year;

    if (searchDate == null && month == null && year == null) {
      effectiveMonth = now.month;
      effectiveYear = now.year;
    } else if (month != null && year == null) {
      // Jika hanya pilih bulan, pasangkan dengan tahun sekarang
      effectiveYear = now.year;
    }

    try {
      // ✅ Kirim parameter ke API Service
      final absensiList = await _apiService.getHistoryAbsensi(
        searchDate: searchDate,
        month: effectiveMonth,
        year: effectiveYear,
      );
      
      _myAbsensiList = absensiList ?? [];
      
      // Update data hari ini (hanya jika tidak sedang memfilter tanggal lain)
      if (searchDate == null && month == null) {
        await fetchCurrentDayAbsensi();
      }
      
      _calculateStatistics();
    } catch (e) {
      _errorMessage = 'Gagal mengambil data absensi: ${e.toString()}';
      debugPrint('Error fetchHistoryAbsensi: $e');
      _myAbsensiList = [];
    } finally {
      if (!silent) setIsLoading(false);
      _isInitialLoadComplete = true;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentDayAbsensi() async {
    final now = DateTime.now();
    try {
      _currentDayAbsensi = _myAbsensiList.firstWhere(
        (absensi) {
          final absensiDate = absensi.checkInAt != null
              ? DateTime.parse(absensi.checkInAt!).toLocal()
              : null;
          if (absensiDate == null) return false;
          return absensiDate.year == now.year &&
              absensiDate.month == now.month &&
              absensiDate.day == now.day;
        },
        orElse: () => Absensi(
          id: -1,
          userId: -1,
          status: '',
          checkInAt: null,
          checkOutAt: null,
          lokasiMasuk: null,
          lokasiPulang: null,
          fotoMasuk: null,
          fotoPulang: null,
          tipe: null,
          createdAt: null,
          updatedAt: null,
          fileBukti: null,
          statusApproval: null,
          catatanAdmin: null,
          fotoMasukUrl: null,
          fotoPulangUrl: null,
          fileBuktiUrl: null,
        ),
      );

      if (_currentDayAbsensi?.id == -1) _currentDayAbsensi = null;
    } catch (_) {
      _currentDayAbsensi = null;
    }
    notifyListeners();
  }

  void _calculateStatistics() {
    _totalHadir = 0;
    _totalIzin = 0;
    _totalSakit = 0;
    _totalTelat = 0;
    _totalLembur = 0;
    _totalTanpaKet = 0;

    for (var absensi in _myAbsensiList) {
      final status = absensi.status.toLowerCase() ?? '';
      final tipe = absensi.tipe?.toLowerCase() ?? '';

      if (status == 'hadir') _totalHadir++;
      if (status == 'izin') _totalIzin++;
      if (status == 'sakit') _totalSakit++;
      if (status == 'telat') _totalTelat++;
      if (status == 'tanpa keterangan') _totalTanpaKet++;
      if (tipe == 'lembur') _totalLembur++;
    }
  }

  // -----------------------------
  // Absensi Methods
  // -----------------------------
  Future<Map<String, dynamic>> absenMasuk({
    required File foto,
    required double lat,
    required double lng,
    required String status,
    bool isMocked = false,
  }) async {
    _uploadProgress = 0;
    setIsLoading(true);
    Map<String, dynamic> result;
    try {
      final stopwatch = Stopwatch()..start();
      
      // 🔥 KOMPRESI GAMBAR SEBELUM KIRIM
      final compressStopwatch = Stopwatch()..start();
      final File compressedFoto = await ImageCompressService.compressImage(foto);
      compressStopwatch.stop();
      
      final int fileSize = await compressedFoto.length();
      debugPrint('⏱️ [Audit] Kompresi: ${compressStopwatch.elapsedMilliseconds}ms, Ukuran: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      final uploadStopwatch = Stopwatch()..start();
      result = await _apiService.absenMasuk(
        foto: compressedFoto, 
        lat: lat, 
        lng: lng, 
        status: status, 
        isMocked: isMocked,
        onProgress: (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        }
      );
      uploadStopwatch.stop();
      stopwatch.stop();
      
      debugPrint('⏱️ [Audit] Upload Absen Masuk: ${uploadStopwatch.elapsedMilliseconds}ms');
      debugPrint('⏱️ [Audit] Total Flow Absen Masuk: ${stopwatch.elapsed.inSeconds} detik');

      if (result['success'] == true) {
        setIsLoading(false); // Tutup loading SEGERA setelah upload sukses
        fetchHistoryAbsensi(silent: true); // Refresh history di background secara silent
      } else {
        _errorMessage = result['message'] ?? 'Absen masuk gagal.';
        setIsLoading(false);
      }
    } catch (e) {
      _errorMessage = 'Error absen masuk: ${e.toString()}';
      result = {'success': false, 'message': _errorMessage};
      setIsLoading(false);
    } finally {
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> absenPulang({
    required File foto,
    required double lat,
    required double lng,
    String? tipe,
    String? keterangan,
    File? fileBukti,
    bool isMocked = false,
  }) async {
    _uploadProgress = 0;
    setIsLoading(true);
    Map<String, dynamic> result;
    try {
      final stopwatch = Stopwatch()..start();

      // 🔥 KOMPRESI GAMBAR SEBELUM KIRIM
      final compressStopwatch = Stopwatch()..start();
      final File compressedFoto = await ImageCompressService.compressImage(foto);
      File? compressedFileBukti;
      if (fileBukti != null) {
        compressedFileBukti = await ImageCompressService.compressImage(fileBukti);
      }
      compressStopwatch.stop();

      final int fileSize = await compressedFoto.length();
      debugPrint('⏱️ [Audit] Kompresi: ${compressStopwatch.elapsedMilliseconds}ms, Ukuran Foto: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      final uploadStopwatch = Stopwatch()..start();
      result = await _apiService.absenPulang(
        foto: compressedFoto, 
        lat: lat, 
        lng: lng, 
        tipe: tipe, 
        keterangan: keterangan,
        fileBukti: compressedFileBukti,
        isMocked: isMocked,
        onProgress: (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        }
      );
      uploadStopwatch.stop();
      stopwatch.stop();
      
      debugPrint('⏱️ [Audit] Upload Absen Pulang: ${uploadStopwatch.elapsedMilliseconds}ms');
      debugPrint('⏱️ [Audit] Total Flow Absen Pulang: ${stopwatch.elapsed.inSeconds} detik');

      if (result['success'] == true) {
        setIsLoading(false); // Tutup loading SEGERA
        fetchHistoryAbsensi(silent: true); // Refresh background secara silent
      } else {
        _errorMessage = result['message'] ?? 'Absen pulang gagal.';
        setIsLoading(false);
      }
    } catch (e) {
      _errorMessage = 'Error absen pulang: ${e.toString()}';
      result = {'success': false, 'message': _errorMessage};
      setIsLoading(false);
    } finally {
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> absenLembur({
    required File foto,
    required double lat,
    required double lng,
    required String jamMulai,
    required String jamSelesai,
    required bool istirahat,
    required String keterangan,
    required String goals,
    required List<File> hasilKerjaFiles,
  }) async {
    setIsLoading(true);
    Map<String, dynamic> result;
    try {
      final stopwatch = Stopwatch()..start();

      // 🔥 KOMPRESI GAMBAR SEBELUM KIRIM
      final compressStopwatch = Stopwatch()..start();
      final File compressedFoto = await ImageCompressService.compressImage(foto);
      final List<File> compressedHasilKerja = await ImageCompressService.compressMultipleImages(hasilKerjaFiles);
      compressStopwatch.stop();

      final int fileSize = await compressedFoto.length();
      debugPrint('⏱️ [Audit] Kompresi: ${compressStopwatch.elapsedMilliseconds}ms, Ukuran Utama: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      final uploadStopwatch = Stopwatch()..start();
      result = await _apiService.absenLembur(
        foto: compressedFoto,
        lat: lat,
        lng: lng,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        istirahat: istirahat,
        keterangan: keterangan,
        goals: goals,
        hasilKerjaFiles: compressedHasilKerja,
        onProgress: (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        },
      );
      uploadStopwatch.stop();
      stopwatch.stop();

      debugPrint('⏱️ [Audit] Upload Absen Lembur: ${uploadStopwatch.elapsedMilliseconds}ms');
      debugPrint('⏱️ [Audit] Total Flow Absen Lembur: ${stopwatch.elapsed.inSeconds} detik');

      if (result['success'] == true) {
        setIsLoading(false);
        fetchHistoryAbsensi();
      } else {
        _errorMessage = result['message'] ?? 'Absen lembur gagal.';
        setIsLoading(false);
      }
    } catch (e) {
      _errorMessage = 'Error absen lembur: ${e.toString()}';
      result = {'success': false, 'message': _errorMessage};
      setIsLoading(false);
    } finally {
      notifyListeners();
    }
    return result;
  }

  /// Pengajuan lembur terpisah dari flow pulang
  Future<Map<String, dynamic>> submitLembur({
    required String jamMulai,
    required String jamSelesai,
    required bool istirahat,
    required String keterangan,
    required String goals,
    required List<File> hasilKerjaFiles,
  }) async {
    setIsLoading(true);
    Map<String, dynamic> result;
    try {
      final stopwatch = Stopwatch()..start();

      // 🔥 KOMPRESI GAMBAR SEBELUM KIRIM
      final compressStopwatch = Stopwatch()..start();
      final List<File> compressedHasilKerja = await ImageCompressService.compressMultipleImages(hasilKerjaFiles);
      compressStopwatch.stop();

      debugPrint('⏱️ [Audit] Kompresi Multiple: ${compressStopwatch.elapsedMilliseconds}ms');

      final uploadStopwatch = Stopwatch()..start();
      result = await _apiService.submitLembur(
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        istirahat: istirahat,
        keterangan: keterangan,
        goals: goals,
        hasilKerjaFiles: compressedHasilKerja,
        onProgress: (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        },
      );
      uploadStopwatch.stop();
      stopwatch.stop();

      debugPrint('⏱️ [Audit] Upload Submit Lembur: ${uploadStopwatch.elapsedMilliseconds}ms');
      debugPrint('⏱️ [Audit] Total Flow Submit Lembur: ${stopwatch.elapsed.inSeconds} detik');

      if (result['success'] == true) {
        setIsLoading(false);
        fetchHistoryAbsensi();
      } else {
        _errorMessage = result['message'] ?? 'Submit lembur gagal.';
        setIsLoading(false);
      }
    } catch (e) {
      _errorMessage = 'Error submit lembur: ${e.toString()}';
      result = {'success': false, 'message': _errorMessage};
      setIsLoading(false);
    } finally {
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> absenSakit({
    required File fileBukti, 
    required String catatan,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    setIsLoading(true);
    Map<String, dynamic> result;
    try {
      final stopwatch = Stopwatch()..start();

      // 🔥 KOMPRESI GAMBAR SEBELUM KIRIM
      final compressStopwatch = Stopwatch()..start();
      final File compressedFileBukti = await ImageCompressService.compressImage(fileBukti);
      compressStopwatch.stop();

      final int fileSize = await compressedFileBukti.length();
      debugPrint('⏱️ [Audit] Kompresi: ${compressStopwatch.elapsedMilliseconds}ms, Ukuran: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      final uploadStopwatch = Stopwatch()..start();
      result = await _apiService.absenSakit(
        fileBukti: compressedFileBukti, 
        catatan: catatan,
        startDate: startDate,
        endDate: endDate,
        onProgress: (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        },
      );
      uploadStopwatch.stop();
      stopwatch.stop();

      debugPrint('⏱️ [Audit] Upload Absen Sakit: ${uploadStopwatch.elapsedMilliseconds}ms');
      debugPrint('⏱️ [Audit] Total Flow Absen Sakit: ${stopwatch.elapsed.inSeconds} detik');

      if (result['success'] == true) {
        await fetchHistoryAbsensi();
      } else {
        _errorMessage = result['message'] ?? 'Pengajuan sakit gagal.';
      }
    } catch (e) {
      _errorMessage = 'Error absen sakit: ${e.toString()}';
      result = {'success': false, 'message': _errorMessage};
    } finally {
      setIsLoading(false);
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> absenIzin({
    required File fileBukti,
    required String catatan,
    required String catatanPanggilan,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    setIsLoading(true);
    Map<String, dynamic> result;
    try {
      final stopwatch = Stopwatch()..start();

      // 🔥 KOMPRESI GAMBAR SEBELUM KIRIM
      final compressStopwatch = Stopwatch()..start();
      final File compressedFileBukti = await ImageCompressService.compressImage(fileBukti);
      compressStopwatch.stop();

      final int fileSize = await compressedFileBukti.length();
      debugPrint('⏱️ [Audit] Kompresi: ${compressStopwatch.elapsedMilliseconds}ms, Ukuran: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      final uploadStopwatch = Stopwatch()..start();
      result = await _apiService.absenIzin(
        fileBukti: compressedFileBukti,
        catatan: catatan,
        catatanPanggilan: catatanPanggilan,
        startDate: startDate,
        endDate: endDate,
        onProgress: (sent, total) {
          _uploadProgress = sent / total;
          notifyListeners();
        },
      );
      uploadStopwatch.stop();
      stopwatch.stop();

      debugPrint('⏱️ [Audit] Upload Absen Izin: ${uploadStopwatch.elapsedMilliseconds}ms');
      debugPrint('⏱️ [Audit] Total Flow Absen Izin: ${stopwatch.elapsed.inSeconds} detik');

      if (result['success'] == true) {
        await fetchHistoryAbsensi();
      } else {
        _errorMessage = result['message'] ?? 'Pengajuan izin gagal.';
      }
    } catch (e) {
      _errorMessage = 'Error absen izin: ${e.toString()}';
      result = {'success': false, 'message': _errorMessage};
    } finally {
      setIsLoading(false);
      notifyListeners();
    }
    return result;
  }

  // -----------------------------
  // ✅ FIXED: Resubmit Absensi (sakit / izin / lembur)
  // -----------------------------
  // lib/providers/absensi_provider.dart
// HANYA BAGIAN METHOD resubmitAbsensi yang diperbaiki

  // ✅ FIXED: Resubmit dengan proper refresh
  Future<Map<String, dynamic>> resubmitAbsensi({
    required int absensiId,
    File? fileBukti,
    String? catatan,
    String? catatanPanggilan,
    File? fotoPulang,
    double? lat,
    double? lng,
    String? jamMulai,
    String? jamSelesai,
    bool? istirahat,
    String? goals,
    List<File>? hasilKerjaFiles,
    required String tipe, // "sakit" or "izin" or "lembur"
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('🔄 [PROVIDER] Mulai resubmit untuk ID: $absensiId, Tipe: $tipe');
    
    setIsLoading(true);
    Map<String, dynamic> result;
    
    try {
      final stopwatch = Stopwatch()..start();
      final compressStopwatch = Stopwatch()..start();
      
      // ✅ Panggil API resubmit sesuai tipe
      if (tipe == 'sakit') {
        if (fileBukti == null) {
          result = {'success': false, 'message': 'File bukti wajib diisi'};
        } else {
          debugPrint('📤 [API] Calling resubmitSakit...');
          // 🔥 KOMPRESI GAMBAR
          final File compressedFileBukti = await ImageCompressService.compressImage(fileBukti);
          compressStopwatch.stop();
          final int fileSize = await compressedFileBukti.length();
          debugPrint('⏱️ [Audit] Kompresi: ${compressStopwatch.elapsedMilliseconds}ms, Ukuran: ${(fileSize / 1024).toStringAsFixed(2)} KB');

          final uploadStopwatch = Stopwatch()..start();
          result = await _apiService.resubmitSakit(
            absensiId: absensiId,
            fileBukti: compressedFileBukti,
            catatan: catatan ?? '',
            startDate: startDate,
            endDate: endDate,
          );
          uploadStopwatch.stop();
          debugPrint('⏱️ [Audit] Upload Resubmit Sakit: ${uploadStopwatch.elapsedMilliseconds}ms');
        }
      } else if (tipe == 'izin') {
        if (fileBukti == null) {
          result = {'success': false, 'message': 'File bukti wajib diisi'};
        } else {
          debugPrint('📤 [API] Calling resubmitIzin...');
          // 🔥 KOMPRESI GAMBAR
          final File compressedFileBukti = await ImageCompressService.compressImage(fileBukti);
          compressStopwatch.stop();
          final int fileSize = await compressedFileBukti.length();
          debugPrint('⏱️ [Audit] Kompresi: ${compressStopwatch.elapsedMilliseconds}ms, Ukuran: ${(fileSize / 1024).toStringAsFixed(2)} KB');

          final uploadStopwatch = Stopwatch()..start();
          result = await _apiService.resubmitIzin(
            absensiId: absensiId,
            fileBukti: compressedFileBukti,
            catatan: catatan ?? '',
            catatanPanggilan: catatanPanggilan ?? '',
            startDate: startDate,
            endDate: endDate,
          );
          uploadStopwatch.stop();
          debugPrint('⏱️ [Audit] Upload Resubmit Izin: ${uploadStopwatch.elapsedMilliseconds}ms');
        }
      } else if (tipe == 'lembur') {
        if (hasilKerjaFiles == null || hasilKerjaFiles.isEmpty) {
          result = {'success': false, 'message': 'Minimal 1 foto bukti wajib diisi'};
        } else {
          debugPrint('📤 [API] Calling resubmitLembur...');
          // 🔥 KOMPRESI GAMBAR
          final List<File> compressedHasilKerja = await ImageCompressService.compressMultipleImages(hasilKerjaFiles);
          compressStopwatch.stop();
          debugPrint('⏱️ [Audit] Kompresi Multiple: ${compressStopwatch.elapsedMilliseconds}ms');
          
          final uploadStopwatch = Stopwatch()..start();
          result = await _apiService.resubmitLembur(
            absensiId: absensiId,
            hasilKerjaFiles: compressedHasilKerja,
            lat: lat ?? 0.0,
            lng: lng ?? 0.0,
            jamMulai: jamMulai ?? '',
            jamSelesai: jamSelesai ?? '',
            istirahat: istirahat ?? false,
            keterangan: catatan ?? '',
            goals: goals ?? '',
          );
          uploadStopwatch.stop();
          debugPrint('⏱️ [Audit] Upload Resubmit Lembur: ${uploadStopwatch.elapsedMilliseconds}ms');
        }
      } else {
        result = {'success': false, 'message': 'Tipe absensi tidak dikenal'};
      }

      stopwatch.stop();
      debugPrint('⏱️ [Audit] Total Flow Resubmit: ${stopwatch.elapsed.inSeconds} detik');
      debugPrint('📥 [API] Response: ${result['success']} - ${result['message']}');

      // ✅ CRITICAL FIX: ALWAYS refresh dari server setelah resubmit
      if (result['success'] == true) {
        debugPrint('✅ [REFRESH] Resubmit berhasil, fetching fresh data from server...');
        
        // Clear dulu data lama
        _myAbsensiList.clear();
        _currentDayAbsensi = null;
        notifyListeners();
        
        // Fetch data baru dari server
        await fetchHistoryAbsensi();
        
        debugPrint('✅ [REFRESH] Data berhasil diperbarui. Total records: ${_myAbsensiList.length}');
      } else {
        _errorMessage = result['message'];
        debugPrint('❌ [ERROR] Resubmit gagal: ${result['message']}');
      }
    } catch (e) {
      _errorMessage = 'Error resubmit absensi: ${e.toString()}';
      debugPrint('❌ [EXCEPTION] Resubmit error: $e');
      result = {'success': false, 'message': _errorMessage};
    } finally {
      setIsLoading(false);
    }
    
    return result;
  }

  Future<Map<String, dynamic>> pengajuanTelat({
  required File fileBukti,
  required String keterangan,
  required int absensiId,
}) async {
  setIsLoading(true);
  Map<String, dynamic> result;
  try {
    final stopwatch = Stopwatch()..start();
    
    // 🔥 KOMPRESI GAMBAR SEBELUM KIRIM
    final compressStopwatch = Stopwatch()..start();
    final File compressedFileBukti = await ImageCompressService.compressImage(fileBukti);
    compressStopwatch.stop();

    final int fileSize = await compressedFileBukti.length();
    debugPrint('⏱️ [Audit] Kompresi: ${compressStopwatch.elapsedMilliseconds}ms, Ukuran: ${(fileSize / 1024).toStringAsFixed(2)} KB');

    final uploadStopwatch = Stopwatch()..start();
    result = await _apiService.pengajuanTelat(
      fileBukti: compressedFileBukti,
      keterangan: keterangan,
      absensiId: absensiId,
    );
    uploadStopwatch.stop();
    stopwatch.stop();

    debugPrint('⏱️ [Audit] Upload Pengajuan Telat: ${uploadStopwatch.elapsedMilliseconds}ms');
    debugPrint('⏱️ [Audit] Total Flow Pengajuan Telat: ${stopwatch.elapsed.inSeconds} detik');

    if (result['success'] == true) {
      await fetchHistoryAbsensi();
    } else {
      _errorMessage = result['message'] ?? 'Pengajuan telat gagal.';
    }
  } catch (e) {
    _errorMessage = 'Error pengajuan telat: ${e.toString()}';
    result = {'success': false, 'message': _errorMessage};
  } finally {
    setIsLoading(false);
    notifyListeners();
  }
  return result;
}

  void resetState() {
    _myAbsensiList = [];
    _currentDayAbsensi = null;
    _isLoading = false;
    _errorMessage = null;
    _isInitialLoadComplete = false;
    _totalHadir = 0;
    _totalIzin = 0;
    _totalSakit = 0;
    _totalTelat = 0;
    _totalLembur = 0;
    _totalTanpaKet = 0;
    notifyListeners();
  }
}