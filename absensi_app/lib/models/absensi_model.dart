import 'dart:convert';

class Absensi {
  final int id;
  final int userId;
  final String status;
  final String? checkInAt;
  final String? checkOutAt;
  final String? lokasiMasuk;
  final String? lokasiPulang;
  final String? fotoMasuk;
  final String? fotoPulang;
  final String? tipe;
  final String? createdAt;
  final String? updatedAt;

  final String? fileBukti;
  final String? statusApproval;
  final String? catatanAdmin;
  final String? keterangan;

  final String? lemburStart;
  final String? lemburEnd;
  final bool? lemburRest;
  final String? lemburKeterangan;

  final String? fotoMasukUrl;
  final String? fotoPulangUrl;
  final String? fileBuktiUrl;

  final int? currentApprovalLevel;
  final Map<String, dynamic>? workflowStatus;
  final String? rejectedBy;

  // 🆕 FIELD BARU: Keterlambatan
  final int? lateMinutes;
  final String? lateDurationText;

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
    this.keterangan,
    this.lemburStart,
    this.lemburEnd,
    this.lemburRest,
    this.lemburKeterangan,
    this.fotoMasukUrl,
    this.fotoPulangUrl,
    this.fileBuktiUrl,
    this.currentApprovalLevel,
    this.workflowStatus,
    this.rejectedBy,
    this.lateMinutes,
    this.lateDurationText,
  });

  Absensi copyWith({
    int? id,
    int? userId,
    String? status,
    String? statusApproval,
    Map<String, dynamic>? workflowStatus,
    String? rejectedBy,
    String? checkInAt,
    String? checkOutAt,
    String? lokasiMasuk,
    String? lokasiPulang,
    String? fotoMasuk,
    String? fotoPulang,
    String? tipe,
    String? createdAt,
    String? updatedAt,
    String? fileBukti,
    String? catatanAdmin,
    String? keterangan,
    String? lemburStart,
    String? lemburEnd,
    bool? lemburRest,
    String? lemburKeterangan,
    String? fotoMasukUrl,
    String? fotoPulangUrl,
    String? fileBuktiUrl,
    int? currentApprovalLevel,
    int? lateMinutes,
    String? lateDurationText,
  }) {
    return Absensi(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      lokasiMasuk: lokasiMasuk ?? this.lokasiMasuk,
      lokasiPulang: lokasiPulang ?? this.lokasiPulang,
      fotoMasuk: fotoMasuk ?? this.fotoMasuk,
      fotoPulang: fotoPulang ?? this.fotoPulang,
      tipe: tipe ?? this.tipe,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileBukti: fileBukti ?? this.fileBukti,
      statusApproval: statusApproval ?? this.statusApproval,
      catatanAdmin: catatanAdmin ?? this.catatanAdmin,
      keterangan: keterangan ?? this.keterangan,
      lemburStart: lemburStart ?? this.lemburStart,
      lemburEnd: lemburEnd ?? this.lemburEnd,
      lemburRest: lemburRest ?? this.lemburRest,
      lemburKeterangan: lemburKeterangan ?? this.lemburKeterangan,
      fotoMasukUrl: fotoMasukUrl ?? this.fotoMasukUrl,
      fotoPulangUrl: fotoPulangUrl ?? this.fotoPulangUrl,
      fileBuktiUrl: fileBuktiUrl ?? this.fileBuktiUrl,
      currentApprovalLevel: currentApprovalLevel ?? this.currentApprovalLevel,
      workflowStatus: workflowStatus ?? this.workflowStatus,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      lateDurationText: lateDurationText ?? this.lateDurationText,
    );
  }

  factory Absensi.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parseWorkflow(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      if (v is String && v.isNotEmpty) {
        try {
          return Map<String, dynamic>.from(jsonDecode(v));
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return Absensi(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      status: json['status']?.toString() ?? '',
      checkInAt: json['check_in_at']?.toString(),
      checkOutAt: json['check_out_at']?.toString(),
      lokasiMasuk: json['lokasi_masuk']?.toString(),
      lokasiPulang: json['lokasi_pulang']?.toString(),
      fotoMasuk: json['foto_masuk']?.toString(),
      fotoPulang: json['foto_pulang']?.toString(),
      tipe: json['tipe']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      fileBukti: json['file_bukti']?.toString(),
      statusApproval: json['status_approval']?.toString(),
      catatanAdmin: json['catatan_admin']?.toString(),
      keterangan: json['keterangan']?.toString() ??
          json['catatan']?.toString() ??
          json['keterangan_izin_sakit']?.toString(),
      lemburStart: json['lembur_start']?.toString(),
      lemburEnd: json['lembur_end']?.toString(),
      lemburRest: json['lembur_rest'] == "1" || json['lembur_rest'] == true,
      lemburKeterangan: json['lembur_keterangan']?.toString(),
      fotoMasukUrl: json['foto_masuk_url']?.toString(),
      fotoPulangUrl: json['foto_pulang_url']?.toString(),
      fileBuktiUrl: json['file_bukti_url']?.toString(),
      currentApprovalLevel: json['current_approval_level'] != null
          ? int.tryParse(json['current_approval_level'].toString())
          : null,
      workflowStatus: parseWorkflow(json['workflow_status']),
      rejectedBy: json['rejected_by']?.toString(),
      // 🆕 Parse late_minutes dan late_duration_text
      lateMinutes: json['late_minutes'] != null
          ? int.tryParse(json['late_minutes'].toString()) ?? 0
          : null,
      lateDurationText: json['late_duration_text']?.toString(),
    );
  }

  String get pendingBy {
    if (workflowStatus == null) return "-";
    try {
      final pending = workflowStatus!.entries.firstWhere(
        (e) => e.value == "pending",
        orElse: () => const MapEntry("Semua Approver", "done"),
      );
      return pending.key;
    } catch (_) {
      return "-";
    }
  }

  bool get isRejected => statusApproval == "rejected";

  String get approvedBy {
    if (workflowStatus == null) return "-";
    final approved = workflowStatus!.entries.where((e) => e.value == "approved");
    if (approved.isNotEmpty) {
      return approved.last.key;
    }
    return "-";
  }

  // 🆕 HELPER: Cek apakah telat
  bool get isLate => (lateMinutes ?? 0) > 0 && status.toLowerCase() == 'hadir';
}