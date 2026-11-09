import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';

class HistoricalAttendanceRequest {
  HistoricalAttendanceRequest({
    required this.jenisPengajuan,
    required this.tanggal,
    required this.keterangan,
    required this.fileBukti,
    required this.employmentType,
    this.jamMasuk,
    this.jamPulang,
    this.jenisIzin,
  });

  static const jenisPengajuanYangDiizinkan = {'lupa_keduanya', 'izin', 'sakit'};

  static const jenisIzinYangDiizinkan = {
    'cuti_tahunan',
    'cuti_melahirkan',
    'cuti_keguguran',
    'cuti_haji',
    'cuti_umroh',
    'cuti_menikah',
    'cuti_khitanan',
    'cuti_baptis',
    'cuti_meninggal',
    'change_off',
    'unpaid_leave',
  };

  final String jenisPengajuan;
  final DateTime? tanggal;
  final String keterangan;
  final File? fileBukti;
  final String employmentType;
  final String? jamMasuk;
  final String? jamPulang;
  final String? jenisIzin;

  bool get isOrganik => employmentType.toLowerCase() == 'organik';

  Map<String, String> validate({DateTime? now}) {
    final errors = <String, String>{};
    final currentTime = now ?? DateTime.now();
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final firstAllowedDate = DateTime(today.year, today.month, today.day - 30);

    if (!jenisPengajuanYangDiizinkan.contains(jenisPengajuan)) {
      errors['jenis_pengajuan'] = 'Pilih jenis pengajuan yang valid.';
    }

    final selectedDate = tanggal == null
        ? null
        : DateTime(tanggal!.year, tanggal!.month, tanggal!.day);
    if (selectedDate == null) {
      errors['tanggal'] = 'Tanggal pengajuan wajib dipilih.';
    } else if (!selectedDate.isBefore(today)) {
      errors['tanggal'] = 'Tanggal harus merupakan tanggal lampau.';
    } else if (selectedDate.isBefore(firstAllowedDate)) {
      errors['tanggal'] = 'Tanggal maksimal 30 hari terakhir.';
    }

    final trimmedDescription = keterangan.trim();
    final descriptionLength = trimmedDescription.runes.length;
    if (descriptionLength < 5 || descriptionLength > 500) {
      errors['keterangan'] = 'Keterangan harus 5–500 karakter.';
    }

    if (fileBukti == null) {
      errors['file_bukti'] = 'Foto bukti wajib dipilih.';
    } else {
      final extension = path.extension(fileBukti!.path).toLowerCase();
      if (!const {'.jpg', '.jpeg', '.png'}.contains(extension)) {
        errors['file_bukti'] = 'Bukti harus berupa gambar JPG, JPEG, atau PNG.';
      }
    }

    if (jenisPengajuan == 'lupa_keduanya') {
      final masuk = _parseTime(jamMasuk);
      final pulang = _parseTime(jamPulang);
      if (masuk == null) {
        errors['jam_masuk'] = 'Jam masuk wajib diisi dengan format HH:mm.';
      }
      if (pulang == null) {
        errors['jam_pulang'] = 'Jam pulang wajib diisi dengan format HH:mm.';
      }
      if (masuk != null && pulang != null) {
        if (pulang <= masuk) {
          errors['jam_pulang'] = 'Jam pulang harus setelah jam masuk.';
        } else if (selectedDate != null &&
            selectedDate.add(Duration(minutes: pulang)).isAfter(currentTime)) {
          errors['jam_pulang'] =
              'Jam pulang tidak boleh melewati waktu sekarang.';
        }
      }
    }

    if (jenisPengajuan == 'izin' &&
        isOrganik &&
        !jenisIzinYangDiizinkan.contains(jenisIzin)) {
      errors['jenis_izin'] = 'Pilih jenis cuti yang valid.';
    }

    return errors;
  }

  Map<String, String> get multipartFields {
    final selectedDate = tanggal!;
    final fields = <String, String>{
      'jenis_pengajuan': jenisPengajuan,
      'tanggal':
          '${selectedDate.year.toString().padLeft(4, '0')}-'
          '${selectedDate.month.toString().padLeft(2, '0')}-'
          '${selectedDate.day.toString().padLeft(2, '0')}',
      'keterangan': keterangan.trim(),
    };

    if (jenisPengajuan == 'lupa_keduanya') {
      fields['jam_masuk'] = jamMasuk!;
      fields['jam_pulang'] = jamPulang!;
    }
    if (jenisPengajuan == 'izin' && isOrganik) {
      fields['jenis_izin'] = jenisIzin!;
    }
    return fields;
  }

  static int? _parseTime(String? value) {
    if (value == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
      return null;
    }
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }
}
