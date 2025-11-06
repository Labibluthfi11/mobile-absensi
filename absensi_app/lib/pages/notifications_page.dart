// lib/pages/notifications_page.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

// <<< Sesuaikan path import ini >>>
import '../api/api.service.dart';
import '../models/notification_model.dart';
import '../screens/home/absensi_pulang_screen.dart'; // Import screen lembur
// <<< AKHIR Penyesuaian path import >>>

class NotificationsPage extends StatefulWidget {
  final ApiService apiService;

  const NotificationsPage({super.key, required this.apiService});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late Future<List<NotificationModel>> _notificationsFuture;
  bool _isRefreshing = false;

  // Warna-warna utama untuk tema modern premium
  static const Color _primaryColor = Color(0xFF4A68FF);
  static const Color _backgroundColor = Color(0xFFF0F2F5);
  static const Color _shadowLight = Color(0xFFFFFFFF);
  static const Color _shadowDark = Color(0xFFD9DCE2);

  @override
  void initState() {
    super.initState();
    _notificationsFuture = widget.apiService.fetchNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isRefreshing = true;
      _notificationsFuture = widget.apiService.fetchNotifications();
    });
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _isRefreshing = false;
    });
  }

  void _navigateToTargetPage(NotificationModel notif) {
    final type = notif.type?.toLowerCase() ?? '';
    final targetId = notif.targetId;

    print('🔍 Debug Navigation:');
    print('   - Type: $type');
    print('   - Target ID: $targetId');
    print('   - Target Page: ${notif.targetPage}');

    // ✅ PRIORITAS KHUSUS untuk LEMBUR - Langsung ke screen dengan parameter
    if (type.contains('lembur')) {
      print('✅ Navigate to: Absensi Pulang Lembur Screen (lembur: true)');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AbsensiPulangScreen(lembur: true),
        ),
      );
      return;
    }

    // Untuk tipe lainnya, gunakan named route
    String route = '/home'; // default fallback

    if (type.contains('sakit')) {
      route = '/sakit_detail';
    } else if (type.contains('izin')) {
      route = '/izin_detail';
    } else if (type.contains('absensi')) {
      route = '/absensi_detail';
    } else if (notif.targetPage != null && notif.targetPage!.isNotEmpty) {
      route = notif.targetPage!;
    }

    print('✅ Navigate to Named Route: $route (with targetId: $targetId)');

    // Gunakan try-catch untuk handle route yang tidak terdaftar
    try {
      Navigator.pushNamed(
        context,
        route,
        arguments: targetId,
      );
    } catch (e) {
      print('⚠️ Route not found: $route - Fallback to /home');
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _handleNotificationTap(NotificationModel notif) async {
    try {
      // Optimistic UI: navigasi dulu
      _navigateToTargetPage(notif);
      
      // Tandai sebagai dibaca di background
      final result = await widget.apiService.markNotificationAsRead(notif.id);
      if (result['success']) {
        // Refresh list setelah berhasil
        setState(() {
          _notificationsFuture = widget.apiService.fetchNotifications();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal memproses notifikasi.'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error handling notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Terjadi kesalahan koneksi.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(NotificationModel notif) {
    final title = notif.title.toLowerCase();
    if (title.contains('pembayaran') || title.contains('gaji')) {
      return Icons.account_balance_wallet_rounded;
    } else if (title.contains('pesanan') || title.contains('order')) {
      return Icons.shopping_cart_rounded;
    } else if (title.contains('promo') || title.contains('diskon')) {
      return Icons.local_activity_rounded;
    } else if (title.contains('lembur')) {
      return Icons.access_alarms_rounded;
    } else if (title.contains('sakit') || title.contains('cuti')) {
      return Icons.medical_services_rounded;
    } else if (title.contains('izin')) {
      return Icons.event_busy_rounded;
    }
    return Icons.info_outline_rounded;
  }

  List<Color> _getNotificationGradient(NotificationModel notif) {
    final title = notif.title.toLowerCase();
    if (title.contains('pembayaran') || title.contains('gaji')) {
      return [const Color(0xFF1ABC9C), const Color(0xFF16A085)];
    } else if (title.contains('pesanan') || title.contains('order')) {
      return [const Color(0xFF3498DB), const Color(0xFF2980B9)];
    } else if (title.contains('promo') || title.contains('diskon')) {
      return [const Color(0xFFF39C12), const Color(0xFFE67E22)];
    } else if (title.contains('lembur')) {
      return [const Color(0xFF9B59B6), const Color(0xFF8E44AD)];
    } else if (title.contains('sakit') || title.contains('cuti') || title.contains('izin')) {
      return [const Color(0xFFE74C3C), const Color(0xFFC0392B)];
    }
    return [const Color(0xFF95A5A6), const Color(0xFF7F8C8D)];
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar Dinamis Premium
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor,
                    _primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20)),
              ),
              child: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
                title: const Text(
                  'Inbox & Notifikasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 28),
                  onPressed: _isRefreshing ? null : _refreshNotifications,
                ),
              ),
            ],
          ),

          // Daftar Notifikasi
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            sliver: FutureBuilder<List<NotificationModel>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_primaryColor),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 80, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            '❌ Gagal memuat notifikasi',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _refreshNotifications,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final notifications = snapshot.data;

                if (notifications == null || notifications.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Kotak masuk masih kosong! ✨',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notif = notifications[index];
                      final gradientColors = _getNotificationGradient(notif);
                      final icon = _getNotificationIcon(notif);
                      final isRead = notif.isRead;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: InkWell(
                          onTap: () => _handleNotificationTap(notif),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isRead ? _backgroundColor : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _shadowDark
                                      .withOpacity(isRead ? 0.8 : 0.5),
                                  offset: const Offset(4, 4),
                                  blurRadius: 10,
                                ),
                                BoxShadow(
                                  color: _shadowLight
                                      .withOpacity(isRead ? 0.5 : 1.0),
                                  offset: const Offset(-4, -4),
                                  blurRadius: 10,
                                ),
                              ],
                              border: isRead
                                  ? null
                                  : Border.all(
                                      color:
                                          gradientColors[0].withOpacity(0.2),
                                      width: 1,
                                    ),
                            ),
                            child: Stack(
                              children: [
                                // Garis indikator belum dibaca
                                if (!isRead)
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: gradientColors[0],
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          bottomLeft: Radius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Icon dengan Gradient
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isRead
                                                ? [
                                                    Colors.grey.shade400,
                                                    Colors.grey.shade300,
                                                  ]
                                                : gradientColors,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: isRead
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: gradientColors[1]
                                                        .withOpacity(0.4),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                        ),
                                        child: Icon(icon,
                                            color: Colors.white, size: 26),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notif.title,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w800,
                                                color: isRead
                                                    ? Colors.grey[700]
                                                    : Colors.grey[900],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              notif.message,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isRead
                                                    ? Colors.grey[500]
                                                    : Colors.grey[700],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .access_time_filled_rounded,
                                                  size: 14,
                                                  color: Colors.grey[400],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDateTime(
                                                      notif.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                    fontWeight: isRead
                                                        ? FontWeight.normal
                                                        : FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: notifications.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}