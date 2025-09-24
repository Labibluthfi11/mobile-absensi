// File: lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'attendance_history_screen.dart';
import 'profile_screen.dart';
import 'absensi_masuk_screen.dart';
import 'absensi_pulang_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // default ke Home

  // Daftar widget untuk tiap tab
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(),         // Home baru
    const AttendanceHistoryScreen(),
    const SizedBox.shrink(),     // Placeholder buat Sakit/Izin
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) { // kalau Sakit/Izin ditekan
      // TODO: bikin modal izin/sakit kayak sebelumnya
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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
      backgroundColor: Colors.white,
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
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital_rounded), label: 'Sakit/Izin'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Widget untuk konten Home
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  void _showAbsensiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pilih Jenis Absensi"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // tutup dialog
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AbsensiMasukScreen()),
              );
            },
            child: const Text("Absensi Masuk"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showPulangDialog(context);
            },
            child: const Text("Absensi Pulang"),
          ),
        ],
      ),
    );
  }

  void _showPulangDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pulang dengan lembur?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AbsensiPulangScreen(lembur: true)),
              );
            },
            child: const Text("Lembur"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AbsensiPulangScreen(lembur: false)),
              );
            },
            child: const Text("Tidak Lembur"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Absensi Hari Ini",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _showAbsensiDialog(context),
          child: const Text("Hadir"),
        ),
      ],
    );
  }
}
