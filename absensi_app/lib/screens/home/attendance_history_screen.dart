import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final absensiProvider = Provider.of<AbsensiProvider>(context);

    // Request attendance data when the screen is loaded, only if there's no data yet and it's not currently loading
    // This ensures fetchMyAbsensi is called only once when the screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!absensiProvider.isInitialLoadComplete && !absensiProvider.isLoading) {
        absensiProvider.fetchMyAbsensi();
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Attendance Statistics
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistik Kehadiran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366), // Dark blue for the title
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.5,
                  children: [
                    _buildStatItem('Hadir:', absensiProvider.totalHadir.toString(), const Color(0xFF007BFF)),
                    _buildStatItem('Tanpa Ket:', absensiProvider.totalTanpaKet.toString(), const Color(0xFFFF0000)),
                    _buildStatItem('Izin:', absensiProvider.totalIzin.toString(), const Color(0xFF8B00FF)),
                    _buildStatItem('Sakit:', absensiProvider.totalSakit.toString(), const Color(0xFF00BFFF)),
                    _buildStatItem('Telat:', absensiProvider.totalTelat.toString(), const Color(0xFFFF8C00)),
                    _buildStatItem('Lembur:', absensiProvider.totalLembur.toString(), const Color(0xFFFFD700)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Section: History Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF007BFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Riwayat Absensi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${absensiProvider.myAbsensiList.length} Records',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Section: Attendance History List
          Expanded(
            child: !absensiProvider.isInitialLoadComplete
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : absensiProvider.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Terjadi kesalahan: ${absensiProvider.errorMessage}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () => absensiProvider.fetchMyAbsensi(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : absensiProvider.myAbsensiList.isEmpty
                        ? const Center(
                            child: Text(
                              'Anda belum memiliki riwayat absensi.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: absensiProvider.myAbsensiList.length,
                            itemBuilder: (context, index) {
                              final absensi = absensiProvider.myAbsensiList[index];
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(
                                              DateTime.parse(absensi.checkInAt!).toLocal(),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(absensi.status),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              absensi.status ?? 'N/A',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Masuk: ${absensi.checkInAt != null ? DateFormat('HH:mm').format(DateTime.parse(absensi.checkInAt!).toLocal()) : '-'} WIB | Pulang: ${absensi.checkOutAt != null ? DateFormat('HH:mm').format(DateTime.parse(absensi.checkOutAt!).toLocal()) : '-'}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
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

  // Helper method to build stat items (private helper function)
  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Helper method to get color based on status (private helper function)
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Hadir':
        return Colors.green;
      case 'Telat':
        return Colors.orange;
      case 'Izin':
        return Colors.purple;
      case 'Sakit':
        return Colors.cyan;
      case 'Tanpa Keterangan':
        return Colors.red;
      case 'Lembur':
        return const Color(0xFFFFD700); // Warna kuning
      default:
        return Colors.grey;
    }
  }
}