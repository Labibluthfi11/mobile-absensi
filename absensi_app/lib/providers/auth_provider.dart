import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api.service.dart';
import '../models/user_model.dart';
import 'dart:convert';

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
  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  AuthProvider() {
    _loadTokenAndUser();
  }

  Future<void> _loadTokenAndUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_authTokenKey);
    String? userDataJson = prefs.getString(_userDataKey);

    if (_token != null && userDataJson != null) {
      try {
        final decodedData = jsonDecode(userDataJson);
        // Pastikan decodedData adalah Map<String, dynamic> sebelum mem-parsing
        if (decodedData is Map<String, dynamic>) {
          _user = User.fromJson(decodedData);
          notifyListeners();
        } else {
          print('Error: User data from SharedPreferences is not a Map<String, dynamic>. Type: ${decodedData.runtimeType}, Data: $decodedData');
          await logout(); // Hapus data yang tidak valid
        }
      } catch (e) {
        print('Error decoding user data from SharedPreferences: $e');
        await logout(); // Hapus data yang tidak valid
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
      final User? userObject = result['user'];

      if (accessToken != null && userObject != null) {
        _token = accessToken;
        _user = userObject;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_authTokenKey, _token!);
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
      rethrow;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String idKaryawan, // <--- DITAMBAHKAN
    required String departemen, // <--- DITAMBAHKAN
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
        idKaryawan: idKaryawan, // <--- DITAMBAHKAN
        departemen: departemen, // <--- DITAMBAHKAN
      );

      final String? accessToken = result['access_token'];
      final User? userObject = result['user'];

      if (accessToken != null && userObject != null) {
        _token = accessToken;
        _user = userObject;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_authTokenKey, _token!);
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
      rethrow;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
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

  String _handleDioError(DioException e) {
    String message = 'An unknown error occurred.';
    if (e.response != null) {
      if (e.response!.data != null && e.response!.data is Map<String, dynamic>) {
        if (e.response!.data.containsKey('message') && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data.containsKey('errors') && e.response!.data['errors'] != null) {
          Map<String, dynamic> errors = e.response!.data['errors'];
          message = errors.values.first[0] ?? 'Validation error.';
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
