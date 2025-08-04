// lib/models/absensi_model.dart

class Absensi {
  final int id;
  final int userId;
  final String status;
  final String? checkInAt;
  final String? checkOutAt;
  final String? lokasiMasuk;
  final String? lokasiPulang;
  final String? fotoMasuk; // <--- PASTIKAN INI ADA
  final String? fotoPulang; // <--- PASTIKAN INI ADA
  final String? tipe;
  final String? createdAt;
  final String? updatedAt;

  Absensi({
    required this.id,
    required this.userId,
    required this.status,
    this.checkInAt,
    this.checkOutAt,
    this.lokasiMasuk,
    this.lokasiPulang,
    this.fotoMasuk, // <--- PASTIKAN INI ADA DI CONSTRUCTOR SEBAGAI NAMED PARAMETER
    this.fotoPulang, // <--- PASTIKAN INI ADA DI CONSTRUCTOR SEBAGAI NAMED PARAMETER
    this.tipe,
    this.createdAt,
    this.updatedAt,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      status: json['status'] as String,
      checkInAt: json['check_in_at'] as String?,
      checkOutAt: json['check_out_at'] as String?,
      lokasiMasuk: json['lokasi_masuk'] as String?,
      lokasiPulang: json['lokasi_pulang'] as String?,
      fotoMasuk: json['foto_masuk'] as String?, // <--- PASTIKAN INI JUGA DI fromJson
      fotoPulang: json['foto_pulang'] as String?, // <--- PASTIKAN INI JUGA DI fromJson
      tipe: json['tipe'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}