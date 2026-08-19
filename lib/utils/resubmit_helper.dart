import 'package:flutter/material.dart';

class ResubmitHelper {
  static Widget buildRejectedNote(String? catatanAdmin) {
    if (catatanAdmin == null || catatanAdmin.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Catatan Penolakan:', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 4),
          Text(catatanAdmin, style: const TextStyle(fontFamily: 'Poppins', color: Colors.red)),
        ],
      ),
    );
  }
}
