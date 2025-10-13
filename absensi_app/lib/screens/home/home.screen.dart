// File: lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; // <-- Import GNav
import '../../providers/auth_provider.dart';
import 'attendance_history_screen.dart';
import 'profile_screen.dart';
import 'absensi_masuk_screen.dart';
import 'absensi_pulang_screen.dart';
import 'absensi_sakit_form_screen.dart';
import 'dart:async'; // Untuk jam realtime

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // default ke Home

  // Daftar widget untuk tiap tab
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(),              // Index 0: Home (UI Modern Card)
    const AttendanceHistoryScreen(),  // Index 1: Riwayat
    const SakitFormScreen(),          // Index 2: Sakit/Izin (Langsung ke form)
    const ProfileScreen(),           // Index 3: Profil
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100], // Background yang lebih soft
      appBar: AppBar(
        title: const Text(
          'Ansel Muda Berkarya',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      
      // ===============================================
      // BOTTOM NAVIGATION BAR MODERN DENGAN GNav
      // ===============================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              // Gaya Tampilan
              gap: 8, // Jarak antara icon dan teks
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.blueAccent, // Warna latar belakang tab yang dipilih
              color: Colors.grey[600], // Warna icon yang tidak dipilih
              
              // Item Navigasi
              tabs: const [
                GButton(
                  icon: Icons.home,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.calendar_month,
                  text: 'Riwayat',
                ),
                GButton(
                  icon: Icons.local_hospital_rounded,
                  text: 'Sakit/Izin',
                ),
                GButton(
                  icon: Icons.person,
                  text: 'Profil',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                _onItemTapped(index); // Memperbarui state saat tab diubah
              },
            ),
          ),
        ),
      ),
      // ===============================================
    );
  }
}

// Widget untuk konten Home (UI Modern Card)
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late String _timeString;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    if (mounted) {
      setState(() {
        _timeString = formattedDateTime;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Format: 13.45.29
    return '${dateTime.hour.toString().padLeft(2, '0')}.${dateTime.minute.toString().padLeft(2, '0')}.${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    // Format: Kamis, 21 Agustus 2025
    const List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const List<String> bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

    String namaHari = hari[dateTime.weekday - 1];
    String namaBulan = bulan[dateTime.month - 1];
    return '$namaHari, ${dateTime.day} $namaBulan ${dateTime.year}';
  }

  void _showAbsensiOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AttendanceOptionsCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(25),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Text(
              "Absensi Hari Ini",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 5),
            // Tanggal
            Text(
              _formatDate(DateTime.now()),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            // Jam Masuk (Contoh Statis) - Kamu bisa ganti ini dengan data dari provider
            const Text(
              "Jam Masuk: 08.00 WIB ",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            // Realtime Clock
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Colors.blueAccent, size: 30),
                const SizedBox(width: 10),
                Text(
                  _timeString,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Tombol "Hadir" (Absensi)
            _buildButton(
              context,
              'Absensi',
              () => _showAbsensiOptions(context),
              backgroundColor: Colors.blueAccent,
              icon: Icons.check_circle,
            ),
            
            const SizedBox(height: 20),
            const Text(
              'Tekan Hadir untuk melakukan Absensi Masuk atau Pulang.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context,
      String text,
      VoidCallback onPressed, {
        Color backgroundColor = Colors.blue,
        IconData? icon,
      }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
    );
  }
}

// Widget Modal Opsi Absensi (Masuk/Pulang)
class AttendanceOptionsCard extends StatelessWidget {
  const AttendanceOptionsCard({super.key});

  // Fungsi untuk menampilkan Pop-up pilihan Lembur / Tidak Lembur
  void _showLemburOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          height: MediaQuery.of(context).size.height * 0.35,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Status Pulang',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 20),
              // Tombol Lembur
              _buildModalButton(
                context,
                'Lembur',
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AbsensiPulangScreen(lembur: true), 
                    ),
                  );
                },
                icon: Icons.access_alarms,
              ),
              const SizedBox(height: 10),
              // Tombol Tidak Lembur
              _buildModalButton(
                context,
                'Tidak Lembur',
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AbsensiPulangScreen(lembur: false),
                    ),
                  );
                },
                backgroundColor: Colors.green,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalButton(
      BuildContext context,
      String text,
      VoidCallback onPressed, {
        Color backgroundColor = Colors.blue,
        IconData? icon,
      }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(fontSize: 18),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pilih Jenis Absensi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 20),
          // Absensi Kehadiran (Masuk)
          _buildModalButton(
            context,
            'Absensi Masuk',
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AbsensiMasukScreen(),
                ),
              );
            },
            icon: Icons.login,
          ),
          const SizedBox(height: 10),
          // Absensi Pulang
          _buildModalButton(
            context,
            'Absensi Pulang',
            () {
              Navigator.pop(context); // Tutup modal Masuk/Pulang
              _showLemburOptions(context); // Buka modal lembur
            },
            backgroundColor: Colors.orange, // Ganti warna agar beda dengan Masuk
            icon: Icons.logout,
          ),
          const SizedBox(height: 20),
          // Tombol Batal
          _buildModalButton(
            context,
            'Batal',
            () => Navigator.pop(context),
            backgroundColor: Colors.red,
            icon: Icons.cancel,
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}