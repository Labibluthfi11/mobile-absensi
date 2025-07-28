import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://127.0.0.1:8000/api'; // <--- Ganti dengan IP lokal Anda atau URL domain Laravel Anda!

  ApiService() {
    // Interceptor untuk menambahkan token ke setiap request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('auth_token');

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        // Handle error global, misalnya logout jika token expired/invalid
        if (error.response?.statusCode == 401) {
          // Contoh: Jika 401 Unauthorized, mungkin token expired atau invalid
          // Anda bisa menambahkan logic untuk logout user di sini
          // Atau biarkan AuthProvider yang menanganinya
          print('Unauthorized request. Token might be expired or invalid.');
        }
        return handler.next(error);
      },
    ));
  }

  // Getter untuk Dio instance
  Dio get dio => _dio;

  // --- Auth Endpoints ---

  Future<Response> login(String email, String password) async {
    try {
      return await _dio.post(
        '$_baseUrl/login',
        data: {
          'email': email,
          'password': password,
        },
      );
    } on DioException catch (e) {
      // Re-throw DioException agar bisa ditangkap di layer atas
      throw e;
    }
  }

  Future<Response> register(String name, String email, String password, String passwordConfirmation) async {
    try {
      return await _dio.post(
        '$_baseUrl/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } on DioException catch (e) {
      throw e;
    }
  }

  Future<Response> logout() async {
    try {
      return await _dio.post('$_baseUrl/logout');
    } on DioException catch (e) {
      throw e;
    }
  }

  Future<Response> getUser() async {
    try {
      return await _dio.get('$_baseUrl/user');
    } on DioException catch (e) {
      throw e;
    }
  }

  // --- Absensi Endpoints ---

  Future<Response> absenMasuk({
    required String lat,
    required String lng,
    required String status,
    required String fotoPath,
  }) async {
    try {
      String fileName = fotoPath.split('/').last;
      FormData formData = FormData.fromMap({
        'lat': lat,
        'lng': lng,
        'status': status,
        'foto': await MultipartFile.fromFile(fotoPath, filename: fileName),
      });

      return await _dio.post(
        '$_baseUrl/absensi/absen-masuk',
        data: formData,
      );
    } on DioException catch (e) {
      throw e;
    }
  }

  Future<Response> absenPulang({
    required String lat,
    required String lng,
    required String status,
    required String fotoPath,
  }) async {
    try {
      String fileName = fotoPath.split('/').last;
      FormData formData = FormData.fromMap({
        'lat': lat,
        'lng': lng,
        'status': status,
        'foto': await MultipartFile.fromFile(fotoPath, filename: fileName),
      });

      return await _dio.post(
        '$_baseUrl/absensi/absen-pulang',
        data: formData,
      );
    } on DioException catch (e) {
      throw e;
    }
  }

  Future<Response> getMyAbsensiHistory() async {
    try {
      return await _dio.get('$_baseUrl/absensi/me');
    } on DioException catch (e) {
      throw e;
    }
  }
}