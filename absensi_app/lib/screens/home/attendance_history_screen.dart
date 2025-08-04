import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/absensi_provider.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final absensiProvider = Provider.of<AbsensiProvider>(context);

    // Minta data absensi saat layar dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (absensiProvider.myAbsensiList.isEmpty && !absensiProvider.isLoading) {
        absensiProvider.fetchMyAbsensi();
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Absensi Bulanan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: absensiProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : absensiProvider.myAbsensiList.isEmpty
                    ? const Center(child: Text('Belum ada riwayat absensi.', style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                        itemCount: absensiProvider.myAbsensiList.length,
                        itemBuilder: (context, index) {
                          final absensi = absensiProvider.myAbsensiList[index];
                          // Menggunakan Card dengan desain yang lebih baik
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.parse(absensi.checkInAt!)),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Divider(height: 16, thickness: 1),
                                  Row(
                                    children: [
                                      const Icon(Icons.login, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Masuk: ${absensi.checkInAt != null ? DateFormat.Hm().format(DateTime.parse(absensi.checkInAt!)) : '-'}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.logout, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pulang: ${absensi.checkOutAt != null ? DateFormat.Hm().format(DateTime.parse(absensi.checkOutAt!)) : '-'}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.info, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Status: ${absensi.status}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  if (absensi.tipe != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.work_history, color: Colors.orange, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Tipe: ${absensi.tipe}', style: const TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
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