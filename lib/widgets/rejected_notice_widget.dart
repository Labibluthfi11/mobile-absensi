import 'package:flutter/material.dart';

class RejectedNoticeWidget extends StatelessWidget {
  final String note;

  const RejectedNoticeWidget({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alasan Penolakan:',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 4),
          Text(note,
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.red)),
        ],
      ),
    );
  }
}
