import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:intl/intl.dart';

// Diubah menjadi StatefulWidget agar bisa menggunakan initState() untuk memuat data.
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  
  // 1. Memuat data saat widget dibuat
  @override
  void initState() {
    super.initState();
    // Memastikan pemanggilan API dilakukan setelah widget terpasang.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // listen: false karena kita berada di initState
      final AbsensiProvider absensiProvider = 
          Provider.of<AbsensiProvider>(context, listen: false);
      
      // Memastikan data selalu di-fetch setiap kali layar diinisialisasi (setelah restart)
      absensiProvider.fetchMyAbsensi(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'id_ID';
    final AbsensiProvider absensiProvider = Provider.of<AbsensiProvider>(context);

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
                    color: Color(0xFF003366), 
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
            child: absensiProvider.isLoading
                ? _buildLoadingSkeleton() // 2. Menggunakan skeleton loading
                : absensiProvider.errorMessage != null
                    ? _buildErrorState(absensiProvider, context)
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
                              final dynamic absensi = absensiProvider.myAbsensiList[index];
                              return _buildHistoryCard(absensi, context); 
                            },
                          ),
          ),
        ],
      ),
    );
  }

// ----------------------------------------------------------------------------------
// HELPER METHODS
// ----------------------------------------------------------------------------------

  // Helper method untuk Skeleton Loading (UI Loading yang bagus)
  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 4, // Tampilkan 4 baris placeholder saat loading
      itemBuilder: (context, index) {
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            height: 120, // Ketinggian menyesuaikan card riwayat
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder untuk Tanggal
                Container(
                  width: 150,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const Divider(height: 15, thickness: 0.5, color: Colors.transparent),
                // Placeholder untuk Masuk
                Container(
                  width: double.infinity,
                  height: 14,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                // Placeholder untuk Pulang
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // Helper method untuk item statistik (TIDAK DIUBAH)
  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Helper method untuk menampilkan Card Riwayat yang Elegan
  Widget _buildHistoryCard(dynamic absensi, BuildContext context) {
    final String? checkInAt = absensi.checkInAt;
    final String? checkOutAt = absensi.checkOutAt;
    final String? status = absensi.status;

    final DateTime? checkInDate = checkInAt != null ? DateTime.parse(checkInAt).toLocal() : null;
    
    final String tanggal = checkInDate != null 
        ? DateFormat('EEEE, d MMMM yyyy').format(checkInDate) 
        : 'Tanggal Tidak Tersedia';
        
    final String jamMasuk = checkInDate != null 
        ? DateFormat('HH:mm').format(checkInDate) 
        : '-';
    
    final String jamPulang = checkOutAt != null 
        ? DateFormat('HH:mm').format(DateTime.parse(checkOutAt).toLocal()) 
        : '-';

    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tanggal
                Text(
                  tanggal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366), 
                  ),
                ),
                // Status Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 15, thickness: 0.5, color: Colors.grey),
            
            // Detail Waktu
            _buildTimeDetail(Icons.login, 'Masuk', '$jamMasuk WIB', Colors.green.shade700),
            const SizedBox(height: 8),
            _buildTimeDetail(Icons.logout, 'Pulang', '$jamPulang WIB', Colors.red.shade700),
          ],
        ),
      ),
    );
  }

  // Helper method untuk detail waktu
  Widget _buildTimeDetail(IconData icon, String label, String time, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 80, 
          child: Text(
            '$label:',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        Text(
          time,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // Helper method untuk state error
  Widget _buildErrorState(AbsensiProvider absensiProvider, BuildContext context) {
    return Center(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method untuk mendapatkan warna berdasarkan status
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'hadir':
        return Colors.green.shade600;
      case 'telat':
        return Colors.orange.shade600;
      case 'izin':
        return Colors.purple.shade600;
      case 'sakit':
        return Colors.lightBlue.shade600;
      case 'tanpa keterangan':
        return Colors.red.shade600;
      case 'lembur':
        return Colors.amber.shade800;
      default:
        return Colors.grey.shade600;
    }
  }
}