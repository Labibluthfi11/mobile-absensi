import 'package:flutter/material.dart';
import '../api/api.service.dart';

class IzinKeluarProvider with ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  bool _isIzinBerjalan = false; 

  IzinKeluarProvider({required ApiService apiService}) : _apiService = apiService;

  bool get isLoading => _isLoading;
  bool get isIzinBerjalan => _isIzinBerjalan;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void ubahStatusIzinBerjalan(bool val) {
    _isIzinBerjalan = val;
    notifyListeners();
  }
}
