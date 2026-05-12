// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../api/api.service.dart'; 
import '../models/user_model.dart'; 
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();
  
  late Future<void> initializationFuture; // Tambahkan ini

  static const String _authTokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  AuthProvider({required ApiService apiService}) 
    : _apiService = apiService,
      super() {
    initializationFuture = _loadTokenAndUser(); // Simpan proses loading ke future
  }

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> setUser(User newUser) async {
    _user = newUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> _loadTokenAndUser() async {
    _token = await _storage.read(key: _authTokenKey);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataJson = prefs.getString(_userDataKey);

    if (_token != null && userDataJson != null) {
      try {
        final decodedData = jsonDecode(userDataJson);
        if (decodedData is Map<String, dynamic>) {
          _user = User.fromJson(decodedData);
          if (_user != null) {
              notifyListeners();
          } else {
            await logout(); 
          }
        } else {
          await logout(); 
        }
      } catch (e) {
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
      final User? userObject = result['user'] as User?; 

      if (accessToken != null && userObject != null) {
        _token = accessToken;
        _user = userObject;

        await _storage.write(key: _authTokenKey, value: _token!);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userDataKey, jsonEncode(_user!.toJson())); 

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = result['message'] ?? 'Login gagal.';
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
      _errorMessage = e.toString();
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
      final User? userObject = result['user'] as User?;

      if (accessToken != null && userObject != null) {
        _token = accessToken;
        _user = userObject;

        await _storage.write(key: _authTokenKey, value: _token!);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userDataKey, jsonEncode(_user!.toJson())); 

        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = result['message'] ?? 'Registrasi gagal.';
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
      _errorMessage = e.toString();
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<void> refreshProfile() async {
    try {
      final User? updatedUser = await _apiService.getAuthenticatedUser(); 
      if (updatedUser != null) {
        _user = updatedUser;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userDataKey, jsonEncode(_user!.toJson()));
        notifyListeners();
      }
    } catch (e) {
      print('Gagal refresh profile: $e');
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.logout(); 
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await _storage.delete(key: _authTokenKey);
      SharedPreferences prefs = await SharedPreferences.getInstance();
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
