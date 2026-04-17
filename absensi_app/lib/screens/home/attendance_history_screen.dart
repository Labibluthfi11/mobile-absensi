import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'package:absensi_app/screens/home/absensi_telat_form_screen.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:intl/intl.dart';

const Color kPrimaryColor = Color(0xFF4F46E5);
const Color kBackgroundColor = Color(0xFFF3F4F6);
const Color kCardColor = Colors.white;

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime? _selectedDate;
  int? _selectedMonth;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final provider = Provider.of<AbsensiProvider>(context, listen: false);
    await provider.fetchMyAbsensi(searchDate: null, month: null, year: null);
    if (mounted) setState(() {}); 
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: kPrimaryColor,
            colorScheme: const ColorScheme.light(primary: kPrimaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedMonth = null;
        _searchQuery = '';
        _searchController.clear();
      });
      _refreshData();
    }
  }

  Map<String, int> _calculateAttendanceStats(List<Absensi> absensiList, String userType) {
    int totalHadir = 0;
    int totalTelat = 0;
    for (var absensi in absensiList) {
      if (absensi.status.toLowerCase() == 'hadir') {
        totalHadir++;
        if (absensi.isLate == true && userType != 'organik' && userType != 'magang') totalTelat++;
      }
    }
    return {'hadir': totalHadir, 'telat': totalTelat};
  }

  List<Absensi> get _filteredList {
    final list = Provider.of<AbsensiProvider>(context).myAbsensiList;
    if (_searchQuery.isEmpty) return list;

    final query = _searchQuery.toLowerCase().trim();
    return list.where((absensi) {
      final dateString = absensi.checkInAt ?? absensi.createdAt;
      if (dateString == null) return false;
      
      final dateValue = DateTime.parse(dateString).toLocal();
      final tanggalFormatted = DateFormat('dd-MM-yyyy').format(dateValue).toLowerCase();
      final namaHari = DateFormat('EEEE', 'id_ID').format(dateValue).toLowerCase();
      final namaBulan = DateFormat('MMMM', 'id_ID').format(dateValue).toLowerCase();

      final status = (absensi.status).toLowerCase();
      final tipe = (absensi.tipe ?? '').toLowerCase();

      return tanggalFormatted.contains(query) ||
             namaHari.contains(query) ||
             namaBulan.contains(query) ||
             status.contains(query) ||
             tipe.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final absensiProvider = Provider.of<AbsensiProvider>(context);
    final userType = Provider.of<AuthProvider>(context, listen: false).user?.employmentType?.toLowerCase() ?? 'freelance';
    final stats = _calculateAttendanceStats(absensiProvider.myAbsensiList, userType);
    final filteredList = _filteredList;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: kPrimaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: kPrimaryColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: const Text('Riwayat Absensi', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF312E81)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                ),
              ),
              actions: [
                if (_selectedDate != null || _selectedMonth != null || _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                          _selectedMonth = null;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _refreshData();
                      },
                    ),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterRow(),
                    const SizedBox(height: 24),
                    _buildStatisticsHorizontal(absensiProvider, stats, userType),
                    const SizedBox(height: 32),
                    _buildHistoryHeader(filteredList.length),
                    const SizedBox(height: 16),
                    
                    if (absensiProvider.isLoading)
                      _buildLoadingSkeleton()
                    else if (filteredList.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) => _buildHistoryCard(filteredList[index], absensiProvider, userType),
                      ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Column(
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari tanggal, hari, status...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Poppins', fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: kPrimaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.grey), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }))
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Filters
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    hint: Text("Pilih Bulan", style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey.shade600)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryColor),
                    isExpanded: true,
                    style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.w600),
                    items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(DateFormat('MMMM', 'id_ID').format(DateTime(2024, index + 1))))),
                    onChanged: (val) {
                      setState(() { _selectedMonth = val; _selectedDate = null; _searchQuery = ''; _searchController.clear(); });
                      _refreshData();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsHorizontal(AbsensiProvider provider, Map<String, int> stats, String userType) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildStatCard('Hadir', stats['hadir'].toString(), const Color(0xFF10B981), Icons.verified_user_rounded),
          if (userType != 'organik' && userType != 'magang')
            _buildStatCard('Telat', stats['telat'].toString(), const Color(0xFFF59E0B), Icons.timer_off_rounded),
          _buildStatCard('Absen', provider.totalTanpaKet.toString(), const Color(0xFFEF4444), Icons.block_rounded),
          _buildStatCard('Izin', provider.totalIzin.toString(), const Color(0xFF8B5CF6), Icons.assignment_ind_rounded),
          _buildStatCard('Sakit', provider.totalSakit.toString(), const Color(0xFF3B82F6), Icons.local_hospital_rounded),
          _buildStatCard('Lembur', provider.totalLembur.toString(), const Color(0xFFFCD34D), Icons.nightlight_round),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: color.withOpacity(0.2), width: 1)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w800, color: color, height: 1)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(int totalRecords) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Data Absensi', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text('$totalRecords Catatan', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: kPrimaryColor)),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Absensi absensi, AbsensiProvider provider, String userType) {
    final String? checkInAt = absensi.checkInAt;
    final String? checkOutAt = absensi.checkOutAt;
    final String status = absensi.status;
    final String? keterangan = absensi.keterangan;
    final String? statusApproval = absensi.statusApproval;
    final DateTime? checkInDate = checkInAt != null ? DateTime.parse(checkInAt).toLocal() : null;

    final String tanggal = checkInDate != null ? DateFormat('EEEE, dd MMM yyyy').format(checkInDate) : 'Tanggal Tidak Tersedia';
    final String jamMasuk = checkInAt != null ? DateFormat('HH:mm').format(checkInDate!) : '--:--';
    final String jamPulang = checkOutAt != null ? DateFormat('HH:mm').format(DateTime.parse(checkOutAt).toLocal()) : '--:--';

    final Color statusColor = _getStatusColor(status);
    final bool isLeaveRecord = status.toLowerCase() == 'sakit' || status.toLowerCase() == 'izin';
    final bool needsApprovalDisplay = isLeaveRecord || absensi.tipe == 'lembur' || absensi.tipe == 'telat';

    String displayedStatusText = status.toUpperCase();
    Color displayedStatusColor = statusColor;

    if (needsApprovalDisplay) {
      final String approval = statusApproval?.toLowerCase() ?? 'pending';
      if (['pending', 'menunggu', 'waiting'].contains(approval)) {
        displayedStatusText = 'DI PROSES';
        displayedStatusColor = const Color(0xFFF59E0B);
      } else if (['approved', 'disetujui'].contains(approval)) {
        displayedStatusText = 'DISETUJUI';
        displayedStatusColor = const Color(0xFF10B981);
      } else if (['rejected', 'ditolak'].contains(approval)) {
        displayedStatusText = 'DITOLAK';
        displayedStatusColor = const Color(0xFFEF4444);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))],
        border: Border.all(color: Colors.grey.shade100, width: 2)
      ),
      child: Column(
        children: [
          // Top Header (Date & Status)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: displayedStatusColor.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(tanggal, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: displayedStatusColor, borderRadius: BorderRadius.circular(10)),
                  child: Text(displayedStatusText, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                )
              ],
            ),
          ),
          
          // Times
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLeaveRecord) ...[
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.info_outline_rounded, color: kPrimaryColor, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(keterangan ?? 'Tanpa keterangan khusus.', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey.shade700, fontStyle: FontStyle.italic))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTimeDetail(Icons.access_time_rounded, 'WAKTU PENGAJUAN', jamMasuk, kPrimaryColor),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTimeDetail(Icons.login_rounded, 'MASUK', jamMasuk, const Color(0xFF10B981)),
                      Container(height: 40, width: 2, color: Colors.grey.shade200),
                      _buildTimeDetail(Icons.logout_rounded, 'PULANG', jamPulang, const Color(0xFFEF4444)),
                    ],
                  ),
                ],

                // Warning / Action (Telat)
                if (absensi.isLate == true && userType != 'organik' && userType != 'magang' && absensi.lateDurationText != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFCD34D), width: 1.5)),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Telat ${absensi.lateDurationText}', style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold))),
                        if (absensi.tipe != 'telat' && userType != 'organik')
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AbsensiTelatFormScreen(absensiHariIni: absensi))),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(10)),
                              child: const Text('Ajukan Alasan', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          )
                      ],
                    ),
                  ),
                ],

                // Workflow Validation
                if (needsApprovalDisplay && absensi.workflowStatus != null && absensi.workflowStatus!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF3F4F6), thickness: 2),
                  const SizedBox(height: 16),
                  const Text('Proses Validasi:', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                  const SizedBox(height: 12),
                  _buildWorkflowWidget(absensi.workflowStatus!),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWorkflowWidget(Map<String, dynamic> workflow) {
    if (workflow.isEmpty) return const SizedBox.shrink();

    String prettyName(String key) {
      final normalized = key.toLowerCase();
      if (normalized.contains('supervisor') || normalized.contains('yuli')) return 'Supervisor';
      if (normalized.contains('manager') || normalized.contains('nu')) return 'Manager';
      if (normalized.contains('hrga') || normalized.contains('nadya')) return 'HRGA';
      return normalized[0].toUpperCase() + normalized.substring(1);
    }

    final Map<String, String> latestStatus = {};
    workflow.forEach((key, value) {
      latestStatus[key.split('.').first.toLowerCase()] = (value ?? '').toString().toLowerCase();
    });

    final order = ['supervisor', 'manager', 'hrga'];
    final sortedEntries = order.where((r) => latestStatus.containsKey(r)).map((r) => MapEntry(r, latestStatus[r]!)).toList();

    return Column(
      children: sortedEntries.map((entry) {
        final role = prettyName(entry.key);
        final status = entry.value;
        Color color = const Color(0xFFF59E0B);
        IconData icon = Icons.schedule_rounded;
        String text = 'Menunggu';

        if (status.contains('approve') || status.contains('disetujui')) { color = const Color(0xFF10B981); icon = Icons.check_circle_rounded; text = 'Disetujui'; } 
        else if (status.contains('reject') || status.contains('ditolak')) { color = const Color(0xFFEF4444); icon = Icons.cancel_rounded; text = 'Ditolak'; }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(role, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const Spacer(),
              Text(text, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeDetail(IconData icon, String label, String time, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(time, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
          ],
        )
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'hadir': return const Color(0xFF10B981);
      case 'telat': return const Color(0xFFF59E0B);
      case 'izin': return const Color(0xFF8B5CF6);
      case 'sakit': return const Color(0xFF3B82F6);
      case 'tanpa keterangan': return const Color(0xFFEF4444);
      case 'lembur': return const Color(0xFFFCD34D);
      default: return Colors.grey.shade500;
    }
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(3, (index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 140,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          children: [
            Container(height: 50, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 80, height: 40, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
                  Container(width: 80, height: 40, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
                ],
              ),
            )
          ],
        ),
      )),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60.0),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.inbox_rounded, color: Colors.grey, size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty ? 'Pencarian Tidak Ditemukan' : 'Belum Ada Riwayat',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ? 'Tidak ada data untuk "$_searchQuery".' : 'Histori absen kamu akan otomatis muncul di sini.',
              textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}