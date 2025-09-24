// File: lib/modals/sakit_izin_modal.dart

import 'package:flutter/material.dart';
import '../screens/home/absensi_sakit_form_screen.dart';

class SakitIzinModal extends StatelessWidget {
  const SakitIzinModal({super.key});

  @override
  Widget build(BuildContext context) {
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
            'Pengajuan Ketidakhadiran',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 20),
          _buildButton(
            context,
            'Izin/Sakit',
            () {
              Navigator.pop(context); // Tutup modal
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SakitFormScreen(),
                ),
              );
            },
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
}