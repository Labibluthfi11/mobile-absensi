import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/models/absensi_model.dart';
import 'package:absensi_app/screens/home/absensi_telat_form_screen.dart';
import 'package:intl/intl.dart';

const Color kPrimaryColor = Color(0xFF152C5C);
const Color kAccentColor = Color(0xFF3B82F6);
const Color kBackgroundColor = Color(0xFFF7F9FB);
const Color kCardColor = Colors.white;

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime? _selectedDate;
  int? _selectedMonth;
  final int _selectedYear = DateTime.now().year;

  // ✅ TAMBAHAN: search bar state
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
    provider.fetchMyAbsensi(
      searchDate: _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
      month: _selectedMonth,
      year: _selectedYear,
    );
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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

  Map<String, int> _calculateAttendanceStats(List<Absensi> absensiList) {
    int totalHadir = 0;
    int totalTelat = 0;
    for (var absensi in absensiList) {
      if (absensi.status.toLowerCase() == 'hadir') {
        totalHadir++;
        if (absensi.isLate == true) totalTelat++;
      }
    }
    return {'hadir': totalHadir, 'telat': totalTelat};
  }

  // ✅ TAMBAHAN: getter filtered list
  List<Absensi> get _filteredList {
    final provider = Provider.of<AbsensiProvider>(context, listen: false);
    final list = provider.myAbsensiList;

    if (_searchQuery.isEmpty) return list;

    final query = _searchQuery.toLowerCase().trim();

    return list.where((absensi) {
      final checkInDate = absensi.checkInAt != null
          ? DateTime.parse(absensi.checkInAt!).toLocal()
          : null;

      final tanggalFormatted = checkInDate != null
          ? DateFormat('dd-MM-yyyy').format(checkInDate).toLowerCase()
          : '';

      final namaHari = checkInDate != null
          ? DateFormat('EEEE', 'id_ID').format(checkInDate).toLowerCase()
          : '';

      final namaBulan = checkInDate != null
          ? DateFormat('MMMM', 'id_ID').format(checkInDate).toLowerCase()
          : '';

      final status = absensi.status.toLowerCase() ?? '';
      final tipe = absensi.tipe?.toLowerCase() ?? '';

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
    final stats = _calculateAttendanceStats(absensiProvider.myAbsensiList);
    final filteredList = _filteredList;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Absensi', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedDate != null || _selectedMonth != null || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.red),
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterRow(),
                const SizedBox(height: 20),
                _buildStatisticsCard(absensiProvider, stats),
                const SizedBox(height: 30),
                _buildHistoryHeader(filteredList.length),
                const SizedBox(height: 20),
                absensiProvider.isLoading
                    ? _buildLoadingSkeleton()
                    : filteredList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildHistoryCard(filteredList[index], absensiProvider);
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Column(
      children: [
        // ✅ SEARCH BAR
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari hari, tanggal, atau status...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: kPrimaryColor.withOpacity(0.6)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // DROPDOWN + DATE PICKER
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    hint: const Text("Pilih Bulan"),
                    isExpanded: true,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(DateFormat('MMMM', 'id_ID').format(DateTime(2024, index + 1))),
                      );
                    }),
                    onChanged: (val) {
                      setState(() {
                        _selectedMonth = val;
                        _selectedDate = null;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                      _refreshData();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(AbsensiProvider absensiProvider, Map<String, int> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: [
            _buildStatItem('Hadir', stats['hadir'].toString(), const Color(0xFF10B981), Icons.check_circle),
            _buildStatItem('Telat', stats['telat'].toString(), const Color(0xFFF59E0B), Icons.access_time_filled),
            _buildStatItem('Tanpa Ket.', absensiProvider.totalTanpaKet.toString(), const Color(0xFFEF4444), Icons.do_not_disturb_alt),
            _buildStatItem('Izin', absensiProvider.totalIzin.toString(), const Color(0xFF8B5CF6), Icons.event_note_outlined),
            _buildStatItem('Sakit', absensiProvider.totalSakit.toString(), const Color(0xFF3B82F6), Icons.medical_services_outlined),
            _buildStatItem('Lembur', absensiProvider.totalLembur.toString(), const Color(0xFFFCD34D), Icons.nightlight_round),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    final double itemWidth = (MediaQuery.of(context).size.width - 60) / 2;
    return Container(
      width: itemWidth,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(int totalRecords) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Riwayat Harian',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kPrimaryColor),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(20)),
          child: Text(
            '$totalRecords Records',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Absensi absensi, AbsensiProvider provider) {
    final String? checkInAt = absensi.checkInAt;
    final String? checkOutAt = absensi.checkOutAt;
    final String status = absensi.status;
    final String? keterangan = absensi.keterangan;
    final String? statusApproval = absensi.statusApproval;

    final DateTime? checkInDate = checkInAt != null ? DateTime.parse(checkInAt).toLocal() : null;

    final String tanggal = checkInDate != null
        ? DateFormat('EEEE, d MMMM yyyy').format(checkInDate)
        : 'Tanggal Tidak Tersedia';
    final String jamMasuk = checkInAt != null ? DateFormat('HH:mm').format(checkInDate!) : '--:--';
    final String jamPulang = checkOutAt != null
        ? DateFormat('HH:mm').format(DateTime.parse(checkOutAt).toLocal())
        : '--:--';

    final Color statusColor = _getStatusColor(status);
    final bool isLeaveRecord = status?.toLowerCase() == 'sakit' || status?.toLowerCase() == 'izin';

    String displayedStatusText = (status ?? 'N/A').toUpperCase();
    Color displayedStatusColor = statusColor;

    if (isLeaveRecord || (absensi.workflowStatus != null && absensi.workflowStatus!.isNotEmpty)) {
      final String approval = statusApproval?.toLowerCase() ?? 'pending';
      if (approval == 'pending' || approval == 'menunggu' || approval == 'waiting') {
        displayedStatusText = 'MENUNGGU APPROVAL';
        displayedStatusColor = Colors.orange.shade700;
      } else if (approval == 'approved' || approval == 'disetujui') {
        displayedStatusText = 'DISETUJUI';
        displayedStatusColor = const Color(0xFF10B981);
      } else if (approval == 'rejected' || approval == 'ditolak') {
        displayedStatusText = 'DITOLAK';
        displayedStatusColor = const Color(0xFFEF4444);
      } else {
        displayedStatusText = (status ?? 'N/A').toUpperCase();
        displayedStatusColor = statusColor;
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border(left: BorderSide(color: displayedStatusColor, width: 6)),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(tanggal,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kPrimaryColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.38,
                      minWidth: 60,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: displayedStatusColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(displayedStatusText,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1, color: Color(0xFFE0E0E0)),
                          if (absensi.isLate == true && absensi.lateDurationText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '⏰ Telat ${absensi.lateDurationText}',
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // ✅ TOMBOL AJUKAN KETERANGAN
                      if (absensi.tipe != 'telat')
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AbsensiTelatFormScreen(
                                  absensiHariIni: absensi,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Ajukan',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            if (isLeaveRecord)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keterangan:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kPrimaryColor)),
                  const SizedBox(height: 4),
                  Text(keterangan ?? 'Tidak ada keterangan spesifik.',
                      style: const TextStyle(fontSize: 16, color: Colors.black87, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                  _buildTimeDetail(Icons.access_time_rounded, 'WAKTU PENGAJUAN', jamMasuk, displayedStatusColor.withOpacity(0.9)),
                  const SizedBox(height: 12),
                  if (absensi.workflowStatus != null && absensi.workflowStatus!.isNotEmpty)
                    _buildWorkflowWidget(absensi),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTimeDetail(Icons.alarm_on, 'MASUK', jamMasuk, Colors.green.shade700),
                      _buildTimeDetail(Icons.alarm_off, 'PULANG', jamPulang, Colors.red.shade700),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (absensi.workflowStatus != null && absensi.workflowStatus!.isNotEmpty)
                    _buildWorkflowWidget(absensi),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkflowWidget(Absensi absensi) {
    final Map<String, dynamic>? workflow = absensi.workflowStatus;
    if (workflow == null || workflow.isEmpty) return const SizedBox.shrink();

    String prettyName(String key) {
      final normalized = key.toLowerCase();
      if (normalized.contains('supervisor') || normalized.contains('yuli')) return 'Supervisor';
      if (normalized.contains('manager') || normalized.contains('nu')) return 'Manager';
      if (normalized.contains('hrga') || normalized.contains('nadya')) return 'HRGA';
      return normalized[0].toUpperCase() + normalized.substring(1);
    }

    final Map<String, String> latestStatus = {};
    workflow.forEach((key, value) {
      final role = key.split('.').first.toLowerCase();
      final status = (value ?? '').toString().toLowerCase();
      latestStatus[role] = status;
    });

    final order = ['supervisor', 'manager', 'hrga'];
    final sortedEntries = order
        .where((role) => latestStatus.containsKey(role))
        .map((role) => MapEntry(role, latestStatus[role]!))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status Approval:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Column(
          children: sortedEntries.map((entry) {
            final role = prettyName(entry.key);
            final status = entry.value;
            Color color;
            IconData icon;
            String statusText;
            if (status.contains('approve')) {
              color = const Color(0xFF10B981);
              icon = Icons.check_circle;
              statusText = 'Approved';
            } else if (status.contains('reject')) {
              color = const Color(0xFFEF4444);
              icon = Icons.cancel;
              statusText = 'Rejected';
            } else {
              color = Colors.amber.shade700;
              icon = Icons.hourglass_top;
              statusText = 'Pending';
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text('$role • $statusText',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeDetail(IconData icon, String label, String time, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color.withOpacity(0.8)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPrimaryColor)),
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
      default: return Colors.grey.shade600;
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            height: 140,
            decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(15)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ShimmerItem(width: 200, height: 18),
                    _ShimmerItem(width: 70, height: 18, borderRadius: 20),
                  ],
                ),
                Divider(height: 25, thickness: 1, color: Colors.transparent),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _ShimmerItem(width: 60, height: 12),
                      SizedBox(height: 5),
                      _ShimmerItem(width: 80, height: 20),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _ShimmerItem(width: 60, height: 12),
                      SizedBox(height: 5),
                      _ShimmerItem(width: 80, height: 20),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 50.0),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 60),
            const SizedBox(height: 15),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Tidak ada hasil untuk "$_searchQuery"'
                  : 'Belum Ada Riwayat Absensi',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Coba kata kunci lain seperti "senin", "hadir", atau "03-2026"'
                  : 'Data akan muncul setelah Anda melakukan absensi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerItem extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerItem({
    required this.width,
    required this.height,
    this.borderRadius = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}