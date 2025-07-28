class Absensi {
  final int id;
  final int userId;
  final String foto; // path foto di server
  final String? fotoUrl; // URL lengkap foto (jika ada)
  final DateTime waktu;
  final String lat;
  final String lng;
  final String tipe; // 'masuk' atau 'pulang'
  final String status; // 'hadir', 'sakit', 'izin', 'cuti' atau 'lembur', 'tidak_lembur'

  Absensi({
    required this.id,
    required this.userId,
    required this.foto,
    this.fotoUrl,
    required this.waktu,
    required this.lat,
    required this.lng,
    required this.tipe,
    required this.status,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['id'],
      userId: json['user_id'],
      foto: json['foto'],
      fotoUrl: json['foto_url'], // Hati-hati dengan nama field ini, pastikan sesuai dari API Laravel
      waktu: DateTime.parse(json['waktu']),
      lat: json['lat'].toString(), // Pastikan di-convert ke String jika dari API bisa number
      lng: json['lng'].toString(), // Pastikan di-convert ke String jika dari API bisa number
      tipe: json['tipe'],
      status: json['status'],
    );
  }
}