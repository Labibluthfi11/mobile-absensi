// File: lib/providers/absensi_provider.dart

import 'package:flutter/material.dart';
import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class AbsensiProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Absensi> _myAbsensiList = [];
  Absensi? _currentDayAbsensi;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialLoadComplete = false;

  // New properties for attendance statistics
  int _totalHadir = 0;
  int _totalIzin = 0;
  int _totalSakit = 0;
  int _totalTelat = 0;
  int _totalLembur = 0;
  int _totalTanpaKet = 0;

  List<Absensi> get myAbsensiList => _myAbsensiList;
  Absensi? get currentDayAbsensi => _currentDayAbsensi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialLoadComplete => _isInitialLoadComplete;

  // New getters for attendance statistics
  int get totalHadir => _totalHadir;
  int get totalIzin => _totalIzin;
  int get totalSakit => _totalSakit;
  int get totalTelat => _totalTelat;
  int get totalLembur => _totalLembur;
  int get totalTanpaKet => _totalTanpaKet;

  AbsensiProvider() {
    fetchMyAbsensi();
  }

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchMyAbsensi() async {
    setIsLoading(true);
    _errorMessage = null;

    try {
      _myAbsensiList = await _apiService.getAbsensiMe();
      await fetchCurrentDayAbsensi();
      // Calculate statistics after fetching the list
      _calculateStatistics();
    } catch (e) {
      _errorMessage = 'Gagal mengambil data absensi: ${e.toString()}';
      print('Error fetching absensi: $e');
      _myAbsensiList = [];
      _currentDayAbsensi = null;
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
          final absensiDate = absensi.checkInAt != null ? DateTime.parse(absensi.checkInAt!).toLocal() : null;
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

      if (_currentDayAbsensi?.id == -1) {
        _currentDayAbsensi = null;
      }
    } catch (e) {
      _currentDayAbsensi = null;
    }
    notifyListeners();
  }
  
  // New private method to calculate statistics from the list
  void _calculateStatistics() {
    _totalHadir = _myAbsensiList.where((a) => a.status == 'Hadir').length;
    _totalIzin = _myAbsensiList.where((a) => a.status == 'Izin').length;
    _totalSakit = _myAbsensiList.where((a) => a.status == 'Sakit').length;
    _totalTelat = _myAbsensiList.where((a) => a.status == 'Telat').length;
    _totalLembur = _myAbsensiList.where((a) => a.tipe == 'Lembur').length;
    _totalTanpaKet = _myAbsensiList.where((a) => a.status == 'Tanpa Keterangan').length;
  }

  Future<Map<String, dynamic>> absenMasuk({
    required File foto,
    required double lat,
    required double lng,
    required String status,
  }) async {
    setIsLoading(true);
    _errorMessage = null;
    Map<String, dynamic> result;

    try {
      result = await _apiService.absenMasuk(
        foto: foto,
        lat: lat,
        lng: lng,
        status: status,
      );

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
  }) async {
    setIsLoading(true);
    _errorMessage = null;
    Map<String, dynamic> result;

    try {
      result = await _apiService.absenPulang(
        foto: foto,
        lat: lat,
        lng: lng,
        tipe: tipe,
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

  Future<Map<String, dynamic>> absenSakit({
    required File fileBukti,
    required String catatan,
  }) async {
    setIsLoading(true);
    _errorMessage = null;
    Map<String, dynamic> result;

    try {
      result = await _apiService.absenSakit(
        fileBukti: fileBukti,
        catatan: catatan,
      );

      if (result['success'] == true) {
        await fetchMyAbsensi();
      } else {
        _errorMessage = result['message'] ?? 'Pengajuan izin sakit gagal.';
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
  }) async {
    setIsLoading(true);
    _errorMessage = null;
    Map<String, dynamic> result;

    try {
      result = await _apiService.absenIzin(
        fileBukti: fileBukti,
        catatan: catatan,
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