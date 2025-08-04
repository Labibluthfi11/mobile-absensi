import 'package:flutter/material.dart';
import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'dart:io';

class AbsensiProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Absensi> _myAbsensiList = [];
  Absensi? _currentDayAbsensi;
  bool _isLoading = false;
  String? _errorMessage;

  List<Absensi> get myAbsensiList => _myAbsensiList;
  Absensi? get currentDayAbsensi => _currentDayAbsensi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AbsensiProvider() {
    // Optional: Fetch data immediately if needed
    // fetchMyAbsensi();
  }

  // Metode setter baru untuk mengontrol status loading
  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Method untuk mengambil riwayat absensi
  Future<void> fetchMyAbsensi() async {
    setIsLoading(true);
    _errorMessage = null;

    try {
      _myAbsensiList = await _apiService.getAbsensiMe();

      // Cek absensi untuk hari ini
      _currentDayAbsensi = _myAbsensiList.firstWhere(
        (absensi) {
          final now = DateTime.now();
          final absensiDate = absensi.checkInAt != null ? DateTime.parse(absensi.checkInAt!).toLocal() : null;
          if (absensiDate == null) return false;
          return absensiDate.year == now.year &&
              absensiDate.month == now.month &&
              absensiDate.day == now.day;
        },
        orElse: () => Absensi(
          id: -1, // Gunakan ID dummy
          userId: -1,
          status: '',
          checkInAt: null,
          checkOutAt: null,
          lokasiMasuk: null,
          lokasiPulang: null,
          fotoMasuk: null,
          fotoPulang: null,
          tipe: null,
          createdAt: '',
          updatedAt: '',
        ),
      );
      // Jika ID dummy, set null lagi agar UI tahu tidak ada absen hari ini
      if (_currentDayAbsensi?.id == -1) {
        _currentDayAbsensi = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch attendance: ${e.toString()}';
      print('Error fetching absensi: $e');
      _myAbsensiList = [];
      _currentDayAbsensi = null;
    } finally {
      setIsLoading(false);
    }
  }

  // Method untuk absen masuk
  Future<void> absenMasuk({
    required File foto,
    required double lat,
    required double lng,
    required String status,
  }) async {
    setIsLoading(true);
    _errorMessage = null;

    try {
      final result = await _apiService.absenMasuk(
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
    } finally {
      setIsLoading(false);
    }
  }

  // Method untuk absen pulang
  Future<void> absenPulang({
    required File foto,
    required double lat,
    required double lng,
    String? tipe,
  }) async {
    setIsLoading(true);
    _errorMessage = null;

    try {
      final result = await _apiService.absenPulang(
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
    } finally {
      setIsLoading(false);
    }
  }

  // Method untuk mereset state provider (misalnya saat logout)
  void resetState() {
    _myAbsensiList = [];
    _currentDayAbsensi = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}