// lib/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final String idKaryawan;
  final String departemen;
  final String employmentType;
  final String? profilePhotoUrl;
  final String? profilePhotoPath;
  // ✅ Data cuti (hanya untuk organik, null untuk freelance)
  final int? sisaCuti;
  final int? totalCutiDiambil;
  final int? tahunCuti;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.idKaryawan,
    required this.departemen,
    required this.employmentType,
    this.profilePhotoUrl,
    this.profilePhotoPath,
    this.sisaCuti,
    this.totalCutiDiambil,
    this.tahunCuti,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInteger(json['id']) ??
          (throw const FormatException('Missing or invalid user id.')),
      name: json['name'] as String? ?? 'N/A',
      email: json['email'] as String? ?? 'user@example.com',
      idKaryawan: json['id_karyawan'] as String? ?? 'N/A',
      departemen: json['departemen'] as String? ?? 'N/A',
      employmentType: json['employment_type'] as String? ?? 'Unknown',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      profilePhotoPath: json['profile_photo_path'] as String?,
      sisaCuti: _parseInteger(json['sisa_cuti']),
      totalCutiDiambil: _parseInteger(json['total_cuti_diambil']),
      tahunCuti: _parseInteger(json['tahun_cuti']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'id_karyawan': idKaryawan,
      'departemen': departemen,
      'employment_type': employmentType,
      'profile_photo_url': profilePhotoUrl,
      'profile_photo_path': profilePhotoPath,
      'sisa_cuti': sisaCuti,
      'total_cuti_diambil': totalCutiDiambil,
      'tahun_cuti': tahunCuti,
    };
  }
}

int? _parseInteger(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  if (value is String) {
    final parsed = num.tryParse(value.trim());
    if (parsed != null &&
        parsed.isFinite &&
        parsed == parsed.roundToDouble()) {
      return parsed.toInt();
    }
  }
  return null;
}
