// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/auth_provider.dart'; // Untuk logout

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              // Navigator otomatis akan kembali ke LoginScreen karena Consumer di main.dart
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Anda telah logout.')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selamat datang, ${authProvider.user?.name ?? 'Pengguna'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Logika untuk absen masuk
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur absen akan datang!')),
                );
              },
              child: const Text('Absen Masuk'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Logika untuk absen pulang
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur absen akan datang!')),
                );
              },
              child: const Text('Absen Pulang'),
            ),
          ],
        ),
      ),
    );
  }
}