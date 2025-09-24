// File: lib/modals/attendance_options_modal.dart

import 'package:flutter/material.dart';
import '../screens/home/absensi_masuk_screen.dart';
import '../screens/home/absensi_pulang_screen.dart';

class AttendanceOptionsModal extends StatelessWidget {
  const AttendanceOptionsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      height: MediaQuery.of(context).size.height * 0.4,
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
            'Absensi Hari Ini',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 20),
          _buildButton(
            context,
            'Absensi Kehadiran',
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AbsensiMasukScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildButton(
            context,
            'Absensi Pulang',
            () {
              Navigator.pop(context); // tutup modal pertama
              _showLemburOptions(context); // buka modal lembur/tidak lembur
            },
          ),
          const SizedBox(height: 10),
          _buildButton(
            context,
            'Batal',
            () => Navigator.pop(context),
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    Color backgroundColor = Colors.blue,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  /// Pop-up pilihan Lembur / Tidak Lembur
  void _showLemburOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          height: MediaQuery.of(context).size.height * 0.3,
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
              _buildButton(
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
              ),
              const SizedBox(height: 10),
              _buildButton(
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
                backgroundColor: Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }
}
