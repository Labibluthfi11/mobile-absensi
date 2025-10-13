// lib/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  // ✅ TIDAK nullable di model, tapi bisa null dari API
  final String idKaryawan; 
  final String departemen;
  final String employmentType; 
  final String? profilePhotoUrl; 
  // ✅ Menambahkan profilePhotoPath jika Anda menggunakannya (Opsional, jika ada di backend)
  final String? profilePhotoPath; 

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.idKaryawan,
    required this.departemen,
    required this.employmentType,
    this.profilePhotoUrl,
    this.profilePhotoPath, // Tambahkan jika perlu
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // KRITIS: Menggunakan ?? untuk memastikan String tidak null.
    // Ini memperbaiki error 'type 'Null' is not a subtype of type 'String''
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'N/A',
      email: json['email'] as String? ?? 'user@example.com',
      // Jika nilai null, gunakan 'N/A' atau '0'
      idKaryawan: json['id_karyawan'] as String? ?? 'N/A', 
      departemen: json['departemen'] as String? ?? 'N/A', 
      employmentType: json['employment_type'] as String? ?? 'Unknown', 
      
      // Properti yang boleh null tetap menggunakan String?
      profilePhotoUrl: json['profile_photo_url'] as String?,
      profilePhotoPath: json['profile_photo_path'] as String?,
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
    };
  }
}