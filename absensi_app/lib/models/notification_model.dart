class NotificationModel {
  final int id;
  final String title;
  final String message; // Isi notifikasi
  final String type;
  
  // Perubahan 1: targetPage dijadikan nullable (String?) 
  // karena di DB Laravel menggunakan nullable()
  final String? targetPage; 
  
  // Perubahan 2: targetId (ID pengajuan yang ditolak) ditambahkan, nullable (int?)
  final int? targetId;
  
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetPage, // Tidak perlu 'required' karena nullable
    this.targetId,   // Tidak perlu 'required' karena nullable
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      
      // Parsing target_page dan target_id (bisa null)
      targetPage: json['target_page'] as String?, 
      targetId: json['target_id'] as int?, 

      // isRead di JSON adalah Integer 0 atau 1. Di Dart kita konversi ke boolean.
      isRead: json['is_read'] == 1, 
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
