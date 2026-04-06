// lib/services/api_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/absensi_model.dart';
import '../models/notification_model.dart';

class ApiService {
  late Dio _dio;
  static const String _authTokenKey = 'auth_token';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.BASE_URL,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_authTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          print('Unauthorized request. Token might be expired or invalid. Attempting to clear token.');
          _deleteToken();
        }
        return handler.next(e);
      },
    ));
  }

  // =========================================================================
  // SECTION AUTH
  // =========================================================================

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String idKaryawan,
    required String departemen,
    required String employmentType,
    required String workLocation,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'id_karyawan': idKaryawan,
          'departemen': departemen,
          'employment_type': employmentType,
          'work_location': workLocation,
        },
      );
      if (response.statusCode == 201) {
        await _saveToken(response.data['access_token']);
        final dynamic userData = response.data['user'];
        if (userData != null && userData is Map<String, dynamic>) {
          return {'success': true, 'user': User.fromJson(userData), 'access_token': response.data['access_token']};
        }
        return {'success': true, 'message': 'Registration successful, but user data not found or invalid.'};
      } else {
        return {'success': false, 'message': response.data['message'] ?? 'Registration failed.'};
      }
    } on DioException catch (e) {
      return _handleDioError(e, 'Registration failed');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      if (response.statusCode == 200) {
        await _saveToken(response.data['access_token']);
        final dynamic userData = response.data['user'];
        if (userData != null && userData is Map<String, dynamic>) {
          return {'success': true, 'user': User.fromJson(userData), 'access_token': response.data['access_token']};
        }
        return {'success': true, 'message': 'Login successful, but user data not found or invalid.'};
      } else {
        return {'success': false, 'message': response.data['message'] ?? 'Login failed.'};
      }
    } on DioException catch (e) {
      return _handleDioError(e, 'Login failed');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } on DioException {
      // Ignore error
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await _deleteToken();
    }
  }

  Future<Map<String, dynamic>> sendOtp({
  required String email,
}) async {
  try {
    final response = await _dio.post(
      '/forgot-password/send-otp',
      data: {'email': email},
    );
    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': response.data['message'] ?? 'OTP telah dikirim ke email Anda.',
      };
    }
    return {
      'success': false,
      'message': response.data['message'] ?? 'Gagal mengirim OTP.',
    };
  } on DioException catch (e) {
    return _handleDioError(e, 'Gagal mengirim OTP');
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

Future<Map<String, dynamic>> verifyOtp({
  required String email,
  required String otp,
}) async {
  try {
    final response = await _dio.post(
      '/forgot-password/verify-otp',
      data: {'email': email, 'otp': otp},
    );
    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': response.data['message'] ?? 'OTP valid.',
      };
    }
    return {
      'success': false,
      'message': response.data['message'] ?? 'OTP tidak valid.',
    };
  } on DioException catch (e) {
    return _handleDioError(e, 'Gagal verifikasi OTP');
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

Future<Map<String, dynamic>> resetPassword({
  required String email,
  required String otp,
  required String password,
  required String passwordConfirmation,
}) async {
  try {
    final response = await _dio.post(
      '/forgot-password/reset-password',
      data: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': response.data['message'] ?? 'Password berhasil direset.',
      };
    }
    return {
      'success': false,
      'message': response.data['message'] ?? 'Gagal reset password.',
    };
  } on DioException catch (e) {
    return _handleDioError(e, 'Gagal reset password');
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

  Future<User?> getAuthenticatedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_authTokenKey)) {
        return null;
      }
      final response = await _dio.get('/user');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic userData = response.data['data'] ?? response.data;
        if (userData is Map<String, dynamic>) {
          return User.fromJson(userData);
        } else {
          print('Error: response.data is not a Map<String, dynamic> in getAuthenticatedUser. Type: ${response.data.runtimeType}, Data: ${response.data}');
          return null;
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _deleteToken();
      }
      _handleDioError(e, 'Failed to fetch authenticated user');
      return null;
    } catch (e) {
      print('Error fetching authenticated user: $e');
      return null;
    }
  }

  // =========================================================================
  // SECTION PROFILE
  // =========================================================================

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String idKaryawan,
    required String departemen,
    required String employmentType,
    File? profilePhoto,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'name': name,
        'email': email,
        'id_karyawan': idKaryawan,
        'departemen': departemen,
        'employment_type': employmentType,
        '_method': 'PUT',
      });

      if (profilePhoto != null) {
        String fileName = profilePhoto.path.split('/').last;
        String? mimeType = lookupMimeType(profilePhoto.path);

        formData.files.add(MapEntry(
          'profile_photo',
          await MultipartFile.fromFile(
            profilePhoto.path,
            filename: fileName,
            contentType: mimeType != null ? MediaType.parse(mimeType) : null,
          ),
        ));
      }

      final response = await _dio.post(
        '/user/profile',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic userData = response.data['user'] ?? response.data['data'];
        if (userData != null && userData is Map<String, dynamic>) {
          return {'success': true, 'message': response.data['message'], 'user': User.fromJson(userData)};
        }
        return {'success': true, 'message': response.data['message'] ?? 'Profile updated successfully, but user data not returned.'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Failed to update profile.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal mengupdate profil');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =========================================================================
  // SECTION ABSENSI
  // =========================================================================

  Future<Map<String, dynamic>> absenMasuk({
    required File foto,
    required double lat,
    required double lng,
    required String status,
  }) async {
    try {
      String fileName = foto.path.split('/').last;
      FormData formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(foto.path, filename: fileName),
        'lat': lat,
        'lng': lng,
        'status': status,
      });

      final response = await _dio.post('/absensi/masuk', data: formData);
      if (response.data != null && response.data['data'] != null) {
        return {'success': true, 'message': response.data['message'], 'data': Absensi.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Absen masuk gagal');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> absenPulang({
    required File foto,
    required double lat,
    required double lng,
    String? tipe,
    String? keterangan,
  }) async {
    try {
      String fileName = foto.path.split('/').last;
      FormData formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(foto.path, filename: fileName),
        'lat': lat,
        'lng': lng,
        if (tipe != null) 'tipe': tipe,
        if (keterangan != null) 'keterangan': keterangan,
      });

      final response = await _dio.post('/absensi/pulang', data: formData);
      if (response.data != null && response.data['data'] != null) {
        return {'success': true, 'message': response.data['message'], 'data': Absensi.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Absen pulang gagal');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> absenLembur({
    required File foto,
    required double lat,
    required double lng,
    required String jamMulai,
    required String jamSelesai,
    required bool istirahat,
    required String keterangan,
  }) async {
    try {
      String fileName = foto.path.split('/').last;
      FormData formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(foto.path, filename: fileName),
        'lat': lat,
        'lng': lng,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'istirahat': istirahat ? '1' : '0',
        'keterangan': keterangan,
      });

      final response = await _dio.post('/absensi/lembur', data: formData);
      if (response.data != null && response.data['data'] != null) {
        return {'success': true, 'message': response.data['message'], 'data': Absensi.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': 'Data absensi lembur tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Absen lembur gagal');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  
  Future<List<Absensi>> getAbsensiMe({String? searchDate, int? month, int? year}) async {
    try {
      
      Map<String, dynamic> queryParameters = {};
      if (searchDate != null) queryParameters['search_date'] = searchDate;
      if (month != null) queryParameters['month'] = month;
      if (year != null) queryParameters['year'] = year;

      
      final response = await _dio.get(
        '/absensi/me',
        queryParameters: queryParameters, 
      );

      if (response.statusCode == 200 && response.data != null && response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((e) => Absensi.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e, 'Gagal mengambil riwayat absensi');
      return [];
    } catch (e) {
      print('Error fetching personal attendance: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> absenSakit({
    required File fileBukti,
    required String catatan,
  }) async {
    try {
      String fileName = fileBukti.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file_bukti': await MultipartFile.fromFile(fileBukti.path, filename: fileName),
        'keterangan_izin_sakit': catatan,
        'keterangan': catatan,
        'status': 'sakit',
      });

      final response = await _dio.post('/absensi/sakit', data: formData);
      if (response.data != null) {
        return {'success': true, 'message': response.data['message'] ?? 'Pengajuan izin sakit berhasil.'};
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal mengajukan izin sakit');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> absenIzin({
    required File fileBukti,
    required String catatan,
    required String catatanPanggilan,
  }) async {
    try {
      String fileName = fileBukti.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file_bukti': await MultipartFile.fromFile(fileBukti.path, filename: fileName),
        'catatan': catatan,
        'catatan_panggilan': catatanPanggilan,
        'tipe': 'izin',
      });

      final response = await _dio.post('/absensi/izin', data: formData);
      if (response.data != null) {
        return {'success': true, 'message': response.data['message'] ?? 'Pengajuan izin berhasil.'};
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal mengajukan izin');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> pengajuanTelat({
  required File fileBukti,
  required String keterangan,
  required int absensiId,
}) async {
  try {
    String fileName = fileBukti.path.split('/').last;
    FormData formData = FormData.fromMap({
      'file_bukti': await MultipartFile.fromFile(fileBukti.path, filename: fileName),
      'keterangan': keterangan,
      'absensi_id': absensiId,
    });

    final response = await _dio.post('/absensi/telat', data: formData);
    if (response.data != null) {
      return {
        'success': true,
        'message': response.data['message'] ?? 'Pengajuan telat berhasil.',
        'late_minutes': response.data['late_minutes'],
      };
    }
    return {'success': false, 'message': 'Data tidak ditemukan.'};
  } on DioException catch (e) {
    return _handleDioError(e, 'Gagal mengajukan keterangan telat');
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

  // =========================================================================
  // NEW METHODS: RESUBMIT
  // =========================================================================

  Future<Map<String, dynamic>> resubmitSakit({
    required int absensiId,
    required File fileBukti,
    required String catatan,
  }) async {
    try {
      String fileName = fileBukti.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file_bukti': await MultipartFile.fromFile(fileBukti.path, filename: fileName),
        'keterangan_izin_sakit': catatan,
        'keterangan': catatan,
        'status': 'pending',
        '_method': 'PUT',
      });

      final response = await _dio.post('/absensi/sakit/$absensiId/resubmit', data: formData);
      if (response.data != null) {
        return {'success': true, 'message': response.data['message'] ?? 'Resubmit izin sakit berhasil.'};
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal resubmit izin sakit');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resubmitIzin({
    required int absensiId,
    required File fileBukti,
    required String catatan,
    required String catatanPanggilan,
  }) async {
    try {
      String fileName = fileBukti.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file_bukti': await MultipartFile.fromFile(fileBukti.path, filename: fileName),
        'catatan': catatan,
        'catatan_panggilan': catatanPanggilan,
        'tipe': 'izin',
        'status': 'pending',
        '_method': 'PUT',
      });

      

      final response = await _dio.post('/absensi/izin/$absensiId/resubmit', data: formData);
      if (response.data != null) {
        return {'success': true, 'message': response.data['message'] ?? 'Resubmit izin berhasil.'};
      }
      return {'success': false, 'message': 'Data absensi tidak ditemukan.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal resubmit izin');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resubmitLembur({
  required int absensiId,
  required File foto,
  required double lat,
  required double lng,
  required String jamMulai,
  required String jamSelesai,
  required bool istirahat,
  required String keterangan,
}) async {
  try {
    String fileName = foto.path.split('/').last;
    FormData formData = FormData.fromMap({
      'foto': await MultipartFile.fromFile(foto.path, filename: fileName),
      'lat': lat,
      'lng': lng,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'istirahat': istirahat ? '1' : '0',
      'keterangan': keterangan,
      'status': 'pending',
      '_method': 'PUT',
    });

    final response = await _dio.post('/absensi/lembur/$absensiId/resubmit', data: formData);
    if (response.data != null) {
      return {
        'success': true,
        'message': response.data['message'] ?? 'Resubmit lembur berhasil.',
        'data': response.data['data']
      };
    }
    return {'success': false, 'message': 'Data tidak ditemukan.'};
  } on DioException catch (e) {
    return _handleDioError(e, 'Gagal resubmit lembur');
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}


  // =========================================================================
  // SECTION NOTIFICATIONS
  // =========================================================================

  Future<int> fetchUnreadCount() async {
    try {
      final response = await _dio.get('/notifications');
      if (response.statusCode == 200 && response.data != null && response.data['data'] is List) {
        final List notifs = response.data['data'];
        final unread = notifs.where((n) {
          final isRead = n['is_read'];
          return isRead == 0 || isRead == '0';
        }).length;
        return unread;
      }
      return 0;
    } on DioException catch (e) {
      _handleDioError(e, 'Gagal mengambil jumlah notifikasi belum dibaca');
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      if (response.statusCode == 200 && response.data != null && response.data['data'] is List) {
        return (response.data['data'] as List)
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _handleDioError(e, 'Gagal mengambil daftar notifikasi');
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    try {
      final response = await _dio.put('/notifications/$notificationId/read');
      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message'] ?? 'Notifikasi berhasil ditandai dibaca.'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Gagal menandai notifikasi.'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Gagal menandai notifikasi dibaca');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =========================================================================
  // SECTION TOKEN & ERROR HANDLING
  // =========================================================================

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  Future<void> _deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  Map<String, dynamic> _handleDioError(DioException e, String defaultMessage) {
    String message = defaultMessage;
    if (e.response != null) {
      if (e.response!.data != null && e.response!.data is Map<String, dynamic>) {
        if (e.response!.data.containsKey('message') && e.response!.data['message'] != null) {
          message = e.response!.data['message'];
        } else if (e.response!.data.containsKey('errors') && e.response!.data['errors'] != null) {
          Map<String, dynamic> errors = e.response!.data['errors'];
          if (errors.values.isNotEmpty && errors.values.first.isNotEmpty) {
            message = errors.values.first[0].toString();
          } else {
            message = 'Validation error.';
          }
        }
      } else {
        message = 'Server error: ${e.response!.statusCode}';
      }
      print('Dio error: ${e.response!.statusCode} - ${e.response!.data}');
    } else {
      message = 'Network error: ${e.message}';
      print('Dio error: ${e.message}');
    }
    return {'success': false, 'message': message};
  }
}
