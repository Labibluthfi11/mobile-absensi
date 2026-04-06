// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
// Pastikan path ini benar! Sesuaikan jika letak ApiService berbeda
import '../api/api.service.dart'; 
import '../models/user_model.dart'; 
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  // Deklarasikan ApiService sebagai field final (Dependency Injection)
  final ApiService _apiService;
  
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // FIX: Tambahkan constructor yang menerima ApiService
  AuthProvider({required ApiService apiService}) 
    : _apiService = apiService,
      super() {
    _loadTokenAndUser();
  }

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Digunakan untuk menyimpan user baru atau user yang terupdate (misal setelah edit profil)
  Future<void> setUser(User newUser) async {
    _user = newUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // KRITIS: Simpan objek user sebagai JSON string
    await prefs.setString(_userDataKey, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> _loadTokenAndUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_authTokenKey);
    String? userDataJson = prefs.getString(_userDataKey);

    if (_token != null && userDataJson != null) {
      try {
        final decodedData = jsonDecode(userDataJson);
        if (decodedData is Map<String, dynamic>) {
          // Gunakan User.fromJson untuk memuat data dari SharedPreferences
          _user = User.fromJson(decodedData);
          if (_user != null) {
              notifyListeners();
          } else {
            print('Error: Failed to parse User from JSON data.');
            await logout(); 
          }
        } else {
          print('Error: User data from SharedPreferences is not a Map<String, dynamic>. Type: ${decodedData.runtimeType}, Data: $decodedData');
          await logout(); 
        }
      } catch (e) {
        print('Error decoding user data from SharedPreferences: $e');
        await logout(); 
      }
    } else {
      _user = null;
      _token = null;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> result = await _apiService.login(
        email: email,
        password: password,
      );

      final String? accessToken = result['access_token'];
      // PERBAIKAN KRITIS: Casting langsung ke User? karena ApiService sudah melakukan User.fromJson()
      final User? userObject = result['user'] as User?; 

      if (accessToken != null && userObject != null) {
        _token = accessToken;
        _user = userObject;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_authTokenKey, _token!);
        // Simpan data user yang sudah di-parse
        await prefs.setString(_userDataKey, jsonEncode(_user!.toJson())); 

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = result['message'] ?? 'Login berhasil, tetapi data user atau token tidak ditemukan.';
        _isLoading = false;
        notifyListeners();
        throw Exception(_errorMessage); 
      }
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _handleDioError(e);
      notifyListeners();
      throw Exception(_errorMessage); 
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
      throw Exception(_errorMessage); 
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String idKaryawan, 
    required String departemen, 
    required String employmentType,
    required String workLocation, 
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> result = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        idKaryawan: idKaryawan, 
        departemen: departemen, 
        employmentType: employmentType, 
        workLocation: workLocation,
      );

      final String? accessToken = result['access_token'];
      // PERBAIKAN KRITIS: Casting langsung ke User?
      final User? userObject = result['user'] as User?;


      if (accessToken != null && userObject != null) {
        _token = accessToken;
        _user = userObject;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_authTokenKey, _token!);
        // Simpan data user yang sudah di-parse
        await prefs.setString(_userDataKey, jsonEncode(_user!.toJson())); 

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = result['message'] ?? 'Registrasi berhasil, tetapi data user atau token tidak ditemukan.';
        _isLoading = false;
        notifyListeners();
        throw Exception(_errorMessage);
      }
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _handleDioError(e);
      notifyListeners();
      throw Exception(_errorMessage);
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.logout(); 
    } on DioException catch (e) {
      // Jika logout API gagal, kita tetap log out di sisi client
      print('Logout API error: ${e.message}'); 
    } finally {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
      await prefs.remove(_userDataKey);
      _token = null;
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fungsi helper untuk handle DioError dari ApiService
  String _handleDioError(DioException e) {
    String message = 'An unknown error occurred.';
    if (e.response != null) {
      if (e.response!.data != null && e.response!.data is Map<String, dynamic>) {
        if (e.response!.data.containsKey('message') && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data.containsKey('errors') && e.response!.data['errors'] != null) {
          Map<String, dynamic> errors = e.response!.data['errors'];
          // Ambil pesan error pertama dari list error
          if (errors.values.isNotEmpty && errors.values.first is List) {
              message = errors.values.first[0];
          } else {
              message = 'Validation error.';
          }
        } else {
          message = 'Server error: ${e.response!.statusCode}';
        }
      } else {
        message = 'Server error: ${e.response!.statusCode}';
      }
    } else {
      message = 'Network error: ${e.message}';
    }
    return message;
  }
}
