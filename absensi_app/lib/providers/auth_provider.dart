// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:absensi_app/api/api.service.dart';
import 'package:absensi_app/models/user.dart';
import 'dart:convert'; // Import this for jsonEncode/jsonDecode

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final ApiService _apiService = ApiService();

  AuthProvider() {
    _loadTokenAndUser(); // Muat token saat inisialisasi provider
  }

  // Muat token dan user dari SharedPreferences
  Future<void> _loadTokenAndUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    String? userDataJson = prefs.getString('user_data');

    if (_token != null && userDataJson != null) {
      try {
        // PERBAIKAN DI SINI: Gunakan jsonDecode
        _user = User.fromJson(jsonDecode(userDataJson));
        notifyListeners();
      } catch (e) {
        // Handle error if userDataJson is corrupted or invalid
        print('Error decoding user data from SharedPreferences: $e');
        await logout(); // Consider logging out if data is invalid
      }
    } else {
      _user = null;
      _token = null;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Response response = await _apiService.login(email, password);
      _token = response.data['token'];
      _user = User.fromJson(response.data['user']);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      // PERBAIKAN DI SINI: Gunakan jsonEncode
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response != null) {
        if (e.response!.statusCode == 422) {
          _errorMessage = e.response!.data['message'] ?? 'Validation error. Please check your credentials.';
        } else if (e.response!.statusCode == 401) {
          _errorMessage = e.response!.data['message'] ?? 'Invalid credentials.';
        } else {
          _errorMessage = 'Server error: ${e.response!.statusCode}';
        }
      } else {
        _errorMessage = 'Network error: ${e.message}';
      }
      notifyListeners();
      rethrow; // Re-throw to allow specific error handling in UI
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password, String passwordConfirmation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Response response = await _apiService.register(name, email, password, passwordConfirmation);
      _token = response.data['token'];
      _user = User.fromJson(response.data['user']);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      // PERBAIKAN DI SINI: Gunakan jsonEncode
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));

      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response != null) {
        if (e.response!.statusCode == 422) {
          _errorMessage = e.response!.data['message'] ?? 'Registration error. Please check your inputs.';
        } else {
          _errorMessage = 'Server error: ${e.response!.statusCode}';
        }
      } else {
        _errorMessage = 'Network error: ${e.message}';
      }
      notifyListeners();
      rethrow;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.logout();
    } on DioException catch (e) {
      // Handle logout error, but still clear local data
      print('Logout API error: ${e.message}');
    } finally {
      // Selalu hapus token dan user dari local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      _token = null;
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }
}