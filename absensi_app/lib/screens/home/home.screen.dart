// File: lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'dart:async';
import 'dart:ui';

import '../../providers/auth_provider.dart';
import '../../api/api.service.dart';
import '../../pages/notifications_page.dart';

import 'attendance_history_screen.dart';
import 'profile_screen.dart';
import 'absensi_masuk_screen.dart';
import 'absensi_pulang_screen.dart';
import 'absensi_sakit_form_screen.dart';
import 'absensi_telat_form_screen.dart';
import 'jadwal_lembur_screen.dart';
import 'absensi_lembur_screen.dart';
import 'start_izin_screen.dart';
import 'end_izin_screen.dart';
import '../../providers/absensi_provider.dart';
import '../../providers/izin_keluar_provider.dart';

const Color kPrimaryColor    = Color(0xFF4F46E5); 
const Color kBackgroundColor = Color(0xFFF3F4F6); 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(),
    const AttendanceHistoryScreen(),
    const SakitFormScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      Future.microtask(() => Navigator.of(context).pushReplacementNamed('/login'));
      return Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimaryColor)));
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.06), offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: GNav(
              gap: 8,
              activeColor: kPrimaryColor,
              iconSize: 26,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: kPrimaryColor.withOpacity(0.12),
              color: Colors.grey.shade400,
              textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: kPrimaryColor, fontSize: 13),
              tabs: const [
                GButton(icon: Icons.dashboard_rounded, text: 'Home'),
                GButton(icon: Icons.receipt_long_rounded, text: 'Riwayat'),
                GButton(icon: Icons.sick_rounded, text: 'Sakit/Izin'),
                GButton(icon: Icons.person_rounded, text: 'Profil'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// HOME CONTENT
// ----------------------------------------------------------------------

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late String _timeString;
  late Timer _timer;
  Future<int> _unreadCountFuture = Future.value(0);

  @override
  void initState() {
    super.initState();
    _timeString = _formatTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnreadCount();
      _refreshData();
    });
  }

  void _loadUnreadCount() {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      setState(() {
        _unreadCountFuture = apiService.fetchUnreadCount();
      });
    } catch (e) {
      setState(() => _unreadCountFuture = Future.value(0));
    }
  }

  Future<void> _refreshData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshProfile(); 
      _loadUnreadCount(); 
    } catch (e) {}
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    if (mounted) setState(() => _timeString = _formatTime(now));
  }

  String _formatTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

  String _formatDate(DateTime d) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${hari[d.weekday - 1]}, ${d.day} ${bulan[d.month - 1]} ${d.year}';
  }


  void _navigateToNotifications(ApiService apiService) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage(apiService: apiService)));
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final apiService = Provider.of<ApiService>(context);
    final absensiProvider = Provider.of<AbsensiProvider>(context);
    final izinProvider = Provider.of<IzinKeluarProvider>(context);
    final user = authProvider.user;
    final userName = user?.name ?? 'Pengguna';

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: kPrimaryColor,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Premium Header
          SliverToBoxAdapter(
            child: _buildGojekStyleHeader(userName, user, apiService),
          ),
          
          // Content Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Layanan Mandiri', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Shift 08:00', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: kPrimaryColor)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tombol Izin Keluar (Hanya jika Sedang Hadir)
                  if (absensiProvider.currentDayAbsensi != null && 
                      (absensiProvider.currentDayAbsensi!.status.toLowerCase() == 'hadir' || absensiProvider.currentDayAbsensi!.status.toLowerCase() == 'terlambat') &&
                      absensiProvider.currentDayAbsensi!.checkOutAt == null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: izinProvider.isIzinBerjalan ? Colors.redAccent.shade700 : Colors.indigo.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (izinProvider.isIzinBerjalan) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const EndIzinScreen()));
                          } else {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const StartIzinScreen()));
                          }
                        },
                        icon: Icon(izinProvider.isIzinBerjalan ? Icons.back_hand_rounded : Icons.exit_to_app_rounded),
                        label: Text(
                          izinProvider.isIzinBerjalan ? "Selesaikan Izin Keluar" : "Izin Keluar",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // Quick Actions Grid (Gojek/Shopee Style)
                  Wrap(
                    spacing: 12,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(
                        icon: Icons.login_rounded,
                        label: 'Masuk',
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsensiMasukScreen())),
                      ),
                      _buildQuickAction(
                        icon: Icons.logout_rounded,
                        label: 'Pulang',
                        color: const Color(0xFFEF4444),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsensiPulangScreen(lembur: false))),
                      ),
                      _buildQuickAction(
                        icon: Icons.more_time_rounded,
                        label: 'Lembur',
                        color: const Color(0xFFF59E0B),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsensiLemburScreen())),
                      ),
                      if (user?.employmentType?.toLowerCase() != 'organik')
                        _buildQuickAction(
                          icon: Icons.timer_off_rounded,
                          label: 'Telat',
                          color: const Color(0xFFF59E0B),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsensiTelatFormScreen())),
                        ),
                      _buildQuickAction(
                        icon: Icons.masks_rounded,
                        label: 'Pengajuan',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SakitFormScreen())),
                      ),
                      _buildQuickAction(
                        icon: Icons.event_available_rounded,
                        label: 'Lembur\nTerjadwal',
                        color: const Color(0xFFF97316),
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const JadwalLemburScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Modern Live Clock Card
                  _buildLiveClockCard(),

                  const SizedBox(height: 24),
                  
                  // Info Banner
                  const InfoBanner(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Gojek / Shopee style Pay/Wallet mimicking Header
  Widget _buildGojekStyleHeader(String userName, dynamic user, ApiService apiService) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0xFF312E81), blurRadius: 20, offset: Offset(0, 5))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: User & Notif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(3),
                     decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                     child: CircleAvatar(
                       radius: 22,
                       backgroundColor: const Color(0xFFE0E7FF),
                       backgroundImage: (user != null && user.profilePhotoUrl != null && user.profilePhotoUrl.isNotEmpty) 
                           ? NetworkImage(user.profilePhotoUrl) 
                           : null,
                       child: (user == null || user.profilePhotoUrl == null || user.profilePhotoUrl.isEmpty)
                           ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U', style: const TextStyle(color: kPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))
                           : null,
                     ),
                   ),
                   const SizedBox(width: 14),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('Selamat Datang,', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
                       Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins', letterSpacing: 0.5)),
                     ],
                   )
                ],
              ),
              // Notification Bell
              GestureDetector(
                onTap: () => _navigateToNotifications(apiService),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                      FutureBuilder<int>(
                        future: _unreadCountFuture,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          if (count > 0) {
                            return Positioned(
                              right: -4, top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444), 
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF4F46E5), width: 2)
                                ),
                                child: Text('${count > 9 ? '9+' : count}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1)),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          
          // GoPay / ShopeePay style "Sisa Cuti" Wallet Card
          if (user != null && user.employmentType == 'organik')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: kPrimaryColor, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Text('Sisa Cuti Tahunan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${user.sisaCuti ?? 12}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, color: Color(0xFF1F2937), fontSize: 32, height: 1)),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4.0, left: 6.0),
                            child: Text('Hari', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 15)),
                          )
                        ],
                      ),
                    ],
                  ),
                  // Separator
                  Container(height: 50, width: 1.5, color: Colors.grey.shade200),
                  // Terpakai
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Terpakai', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text('${user.totalCutiDiambil ?? 0} Hari', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: kPrimaryColor, fontSize: 18)),
                    ],
                  )
                ],
              ),
            )
          else 
            // If not organik, just show a nice date indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.calendar_month_rounded, color: kPrimaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal Hari Ini', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.grey.shade500, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_formatDate(DateTime.now()), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFF1F2937), fontSize: 16)),
                    ],
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade100, width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))]
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        ],
      ),
    );
  }

  Widget _buildLiveClockCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF1F2937).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30, top: -20,
            child: Icon(Icons.access_time_filled_rounded, size: 140, color: Colors.white.withOpacity(0.04)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_rounded, color: Colors.greenAccent, size: 14),
                    SizedBox(width: 6),
                    Text('Waktu Server AKTIF', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(_timeString, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, height: 1, letterSpacing: 2)),
              const SizedBox(height: 10),
              Text(_formatDate(DateTime.now()), style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withOpacity(0.6), fontSize: 15)),
            ],
          )
        ],
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle),
            child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pengumuman Penting', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0369A1))),
                const SizedBox(height: 6),
                Text('Pastikan Anda berada di area kantor saat melakukan absensi masuk maupun pulang agar ditrack akurat.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF075985), height: 1.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}