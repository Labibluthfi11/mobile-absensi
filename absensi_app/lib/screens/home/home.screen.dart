import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/absensi_camera_screen.dart';
import 'attendance_history_screen.dart';
import 'profile_screen.dart';
import 'absensi_sakit_form_screen.dart'; // Import file baru

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Mengatur default index ke Absen (tengah)

  // Daftar widget/layar yang akan ditampilkan
  static const List<Widget> _widgetOptions = <Widget>[
    AttendanceHistoryScreen(),
    AbsensiCameraScreen(),
    SakitFormScreen(), // Tambahkan form sakit ke daftar layar
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Pastikan pengguna sudah terautentikasi sebelum melanjutkan
    if (!authProvider.isAuthenticated) {
      Future.microtask(() => Navigator.of(context).pushReplacementNamed('/login'));
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang utama aplikasi putih
      appBar: AppBar(
        title: const Text(
          'Ansel Muda Berkarya', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ), // Tanda kurung dan koma yang hilang sudah ditambahkan
        ),
        backgroundColor: Colors.blueAccent, // Latar belakang AppBar biru
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Absen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_rounded),
            label: 'Sakit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
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
