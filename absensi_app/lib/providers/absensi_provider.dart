import 'package:flutter/material.dart';
import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'dart:io';

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

  // Getters
  List<Absensi> get myAbsensiList => _myAbsensiList;
  Absensi? get currentDayAbsensi => _currentDayAbsensi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialLoadComplete => _isInitialLoadComplete;

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
    await fetchMyAbsensi();
  }

 // ✅ UPDATE: Tambahkan parameter optional untuk filter
  Future<void> fetchMyAbsensi({String? searchDate, int? month, int? year}) async {
    setIsLoading(true);
    _errorMessage = null;

    try {
      // ✅ Kirim parameter ke API Service
      final absensiList = await _apiService.getAbsensiMe(
        searchDate: searchDate,
        month: month,
        year: year,
      );
      
      _myAbsensiList = absensiList ?? [];
      
      // Update data hari ini (hanya jika tidak sedang memfilter tanggal lain)
      if (searchDate == null && month == null) {
        await fetchCurrentDayAbsensi();
      }
      
      _calculateStatistics();
    } catch (e) {
      _errorMessage = 'Gagal mengambil data absensi: ${e.toString()}';
      debugPrint('Error fetchMyAbsensi: $e');
      _myAbsensiList = [];
    } finally {
      setIsLoading(false);
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
  }) async {
    setIsLoading(true);
    Map<String, dynamic> result;
    try {
      result = await _apiService.absenMasuk(foto: foto, lat: lat, lng: lng, status: status);
      if (result['success'] == true) {
        await fetchMyAbsensi();
      } else {
        _errorMessage = result['message'] ?? 'Absen masuk gagal.';
      }
    } catch (e) {
      _errorMessage = 'Error absen masuk: ${e.toString()}';
      result = {'success': false, 'message': _errorMessage};
    } finally {
      setIsLoading(false);
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
  }) async {
    setIsLoading(true);
    Map<String, dynamic> result;
    try {
      result = await _apiService.absenPulang(
        foto: foto, 
        lat: lat, 
        lng: lng, 
        tipe: tipe, 
        keterangan: keterangan
      );
      if (result['success'] == true) {
        await fetchMyAbsensi();
      } else {
        _errorMessage = result['message'] ?? 'Absen pulang gagal.';
      }
    } catch (e) {
      _errorMessage = 'Error absen pulang: ${e.toString()}';
      result = {'success': false, 'message': _errorMessage};
    } finally {
      setIsLoading(false);
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
      result = await _apiService.absenLembur(
        foto: foto,
        lat: lat,
        lng: lng,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        istirahat: istirahat,
        keterangan: keterangan,
        goals: goals,
        hasilKerjaFiles: hasilKerjaFiles,
      );
      if (result['success'] == true) {
        await fetchMyAbsensi();
      } else {
        _errorMessage = result['message'] ?? 'Absen lembur gagal.';
      }
    } catch (e) {
      _errorMessage = 'Error absen lembur: ${e.toString()}';
      result = {'success': false, 'message': _errorMessage};
    } finally {
      setIsLoading(false);
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> absenSakit({
    required File fileBukti, 
    required String catatan
  }) async {
    setIsLoading(true);
    Map<String, dynamic> result;
    try {
      result = await _apiService.absenSakit(fileBukti: fileBukti, catatan: catatan);
      if (result['success'] == true) {
        await fetchMyAbsensi();
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
      result = await _apiService.absenIzin(
        fileBukti: fileBukti,
        catatan: catatan,
        catatanPanggilan: catatanPanggilan,
        startDate: startDate,
        endDate: endDate,
      );
      if (result['success'] == true) {
        await fetchMyAbsensi();
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
    required String tipe, // "sakit" or "izin" or "lembur"
  }) async {
    debugPrint('🔄 [PROVIDER] Mulai resubmit untuk ID: $absensiId, Tipe: $tipe');
    
    setIsLoading(true);
    Map<String, dynamic> result;
    
    try {
      // ✅ Panggil API resubmit sesuai tipe
      if (tipe == 'sakit') {
        if (fileBukti == null) {
          result = {'success': false, 'message': 'File bukti wajib diisi'};
        } else {
          debugPrint('📤 [API] Calling resubmitSakit...');
          result = await _apiService.resubmitSakit(
            absensiId: absensiId,
            fileBukti: fileBukti,
            catatan: catatan ?? '',
          );
        }
      } else if (tipe == 'izin') {
        if (fileBukti == null) {
          result = {'success': false, 'message': 'File bukti wajib diisi'};
        } else {
          debugPrint('📤 [API] Calling resubmitIzin...');
          result = await _apiService.resubmitIzin(
            absensiId: absensiId,
            fileBukti: fileBukti,
            catatan: catatan ?? '',
            catatanPanggilan: catatanPanggilan ?? '',
          );
        }
      } else if (tipe == 'lembur') {
        if (fotoPulang == null) {
          result = {'success': false, 'message': 'Foto wajib diisi'};
        } else {
          debugPrint('📤 [API] Calling resubmitLembur...');
          result = await _apiService.resubmitLembur(
            absensiId: absensiId,
            foto: fotoPulang,
            lat: lat ?? 0.0,
            lng: lng ?? 0.0,
            jamMulai: jamMulai ?? '',
            jamSelesai: jamSelesai ?? '',
            istirahat: istirahat ?? false,
            keterangan: catatan ?? '',
          );
        }
      } else {
        result = {'success': false, 'message': 'Tipe absensi tidak dikenal'};
      }

      debugPrint('📥 [API] Response: ${result['success']} - ${result['message']}');

      // ✅ CRITICAL FIX: ALWAYS refresh dari server setelah resubmit
      if (result['success'] == true) {
        debugPrint('✅ [REFRESH] Resubmit berhasil, fetching fresh data from server...');
        
        // Clear dulu data lama
        _myAbsensiList.clear();
        _currentDayAbsensi = null;
        notifyListeners();
        
        // Fetch data baru dari server
        await fetchMyAbsensi();
        
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
    result = await _apiService.pengajuanTelat(
      fileBukti: fileBukti,
      keterangan: keterangan,
      absensiId: absensiId,
    );
    if (result['success'] == true) {
      await fetchMyAbsensi();
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