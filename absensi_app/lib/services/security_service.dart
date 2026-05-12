import 'package:safe_device/safe_device.dart';
import 'package:flutter/foundation.dart';

class SecurityService {
  /// Memeriksa apakah perangkat aman untuk menjalankan aplikasi.
  /// Memeriksa Root, Jailbreak, dan apakah ini perangkat asli (bukan emulator).
  static Future<Map<String, dynamic>> checkDeviceSecurity() async {
    try {
      bool isJailBroken = await SafeDevice.isJailBroken;
      bool isRealDevice = await SafeDevice.isRealDevice;
      bool isSafe = !isJailBroken && (isRealDevice || kDebugMode);

      return {
        'isSafe': isSafe,
        'isJailBroken': isJailBroken,
        'isRealDevice': isRealDevice,
        'message': !isSafe 
            ? (isJailBroken ? 'Perangkat terdeteksi Root/Jailbreak.' : 'Aplikasi tidak dapat berjalan di Emulator.')
            : 'Perangkat aman.'
      };
    } catch (e) {
      debugPrint('Security Check Error: $e');
      return {'isSafe': true, 'message': 'Gagal melakukan validasi keamanan.'};
    }
  }

  /// Memeriksa apakah lokasi saat ini dipalsukan (Mock Location).
  static Future<bool> isMockLocation() async {
    try {
      return await SafeDevice.isMockLocation;
    } catch (e) {
      debugPrint('Mock Location Check Error: $e');
      return false;
    }
  }
}
