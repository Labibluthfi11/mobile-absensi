// lib/models/absensi_model.dart

class Absensi {
  final int id;
  final int userId;
  final String status;
  final String? checkInAt;
  final String? checkOutAt;
  final String? lokasiMasuk;
  final String? lokasiPulang;
  final String? fotoMasuk; // Path foto di server storage
  final String? fotoPulang; // Path foto di server storage
  final String? tipe;
  final String? createdAt;
  final String? updatedAt;
  
  // Kolom baru dari backend
  final String? fileBukti;
  final String? statusApproval;
  final String? catatanAdmin;

  // URL lengkap untuk foto (disediakan oleh API Laravel)
  final String? fotoMasukUrl;
  final String? fotoPulangUrl;
  final String? fileBuktiUrl;


  Absensi({
    required this.id,
    required this.userId,
    required this.status,
    this.checkInAt,
    this.checkOutAt,
    this.lokasiMasuk,
    this.lokasiPulang,
    this.fotoMasuk,
    this.fotoPulang,
    this.tipe,
    this.createdAt,
    this.updatedAt,
    this.fileBukti,
    this.statusApproval,
    this.catatanAdmin,
    this.fotoMasukUrl,
    this.fotoPulangUrl,
    this.fileBuktiUrl,
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
      fotoMasuk: json['foto_masuk'] as String?,
      fotoPulang: json['foto_pulang'] as String?,
      tipe: json['tipe'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      
      // Parsing kolom baru
      fileBukti: json['file_bukti'] as String?,
      statusApproval: json['status_approval'] as String?,
      catatanAdmin: json['catatan_admin'] as String?,

      // Parsing URL foto dari API Laravel
      fotoMasukUrl: json['foto_masuk_url'] as String?,
      fotoPulangUrl: json['foto_pulang_url'] as String?,
      fileBuktiUrl: json['file_bukti_url'] as String?,
    );
  }
}
