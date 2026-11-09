import 'package:absensi_app/core/app_colors.dart';
import 'package:absensi_app/models/historical_attendance_request.dart';
import 'package:absensi_app/providers/absensi_provider.dart';
import 'package:absensi_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';

class HistoricalAttendanceRequestScreen extends StatefulWidget {
  const HistoricalAttendanceRequestScreen({super.key});

  @override
  State<HistoricalAttendanceRequestScreen> createState() =>
      _HistoricalAttendanceRequestScreenState();
}

class _HistoricalAttendanceRequestScreenState
    extends State<HistoricalAttendanceRequestScreen> {
  static const _leaveTypes = <String, String>{
    'cuti_tahunan': 'Cuti Tahunan',
    'cuti_melahirkan': 'Cuti Melahirkan',
    'cuti_keguguran': 'Cuti Keguguran',
    'cuti_haji': 'Cuti Haji',
    'cuti_umroh': 'Cuti Umroh',
    'cuti_menikah': 'Cuti Menikah',
    'cuti_khitanan': 'Cuti Khitanan',
    'cuti_baptis': 'Cuti Baptis',
    'cuti_meninggal': 'Cuti Meninggal',
    'change_off': 'Change Off',
    'unpaid_leave': 'Unpaid Leave',
  };

  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final _imagePicker = ImagePicker();
  String _jenisPengajuan = 'lupa_keduanya';
  DateTime? _tanggal;
  TimeOfDay? _jamMasuk;
  TimeOfDay? _jamPulang;
  String? _jenisIzin;
  File? _fileBukti;
  bool _isSubmitting = false;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  bool get _isOrganik =>
      context.read<AuthProvider>().user?.employmentType.toLowerCase() ==
      'organik';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? DateTime(today.year, today.month, today.day - 1),
      firstDate: DateTime(today.year, today.month, today.day - 30),
      lastDate: DateTime(today.year, today.month, today.day - 1),
      helpText: 'Pilih tanggal absensi',
    );
    if (picked != null && mounted) {
      setState(() {
        _tanggal = DateTime(picked.year, picked.month, picked.day);
        _fieldErrors.remove('tanggal');
      });
    }
  }

  Future<void> _pickTime({required bool checkIn}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: checkIn
          ? (_jamMasuk ?? const TimeOfDay(hour: 8, minute: 0))
          : (_jamPulang ?? const TimeOfDay(hour: 17, minute: 0)),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (checkIn) {
          _jamMasuk = picked;
          _fieldErrors.remove('jam_masuk');
        } else {
          _jamPulang = picked;
          _fieldErrors.remove('jam_pulang');
        }
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;

      final file = File(picked.path);
      final extension = picked.path.split('.').last.toLowerCase();
      if (!const {'jpg', 'jpeg', 'png'}.contains(extension)) {
        _showMessage('Pilih foto berformat JPG, JPEG, atau PNG.');
        return;
      }
      if (await file.length() > 2 * 1024 * 1024) {
        _showMessage('Ukuran foto bukti maksimal 2 MB.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _fileBukti = file;
        _fieldErrors.remove('file_bukti');
      });
    } catch (error) {
      if (mounted) _showMessage('Gagal mengambil foto bukti: $error');
    }
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil foto'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user;
    final request = HistoricalAttendanceRequest(
      jenisPengajuan: _jenisPengajuan,
      tanggal: _tanggal,
      keterangan: _keteranganController.text,
      fileBukti: _fileBukti,
      employmentType: user?.employmentType ?? 'freelance',
      jamMasuk: _formatTime(_jamMasuk),
      jamPulang: _formatTime(_jamPulang),
      jenisIzin: _jenisIzin,
    );
    final validationErrors = request.validate();
    if (validationErrors.isNotEmpty) {
      setState(() => _fieldErrors = validationErrors);
      _showMessage(validationErrors.values.first);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _fieldErrors.clear();
    });
    try {
      final result = await context.read<AbsensiProvider>().ajukanAbsensiLampau(
        request: request,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) =>
              _buildSuccessDialog(dialogContext, result['message']?.toString()),
        );
        if (mounted) Navigator.pop(context, true);
        return;
      }

      final responseData = result['data'];
      final errors = _readFieldErrors(responseData);
      if (result['statusCode'] == 422 && errors.isNotEmpty) {
        setState(() => _fieldErrors = errors);
      }
      _showMessage(
        result['message']?.toString() ??
            (result['statusCode'] == 409
                ? 'Terjadi konflik dengan data absensi.'
                : 'Pengajuan gagal dikirim.'),
      );
    } catch (error) {
      if (mounted) _showMessage('Gagal mengirim pengajuan: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Map<String, String> _readFieldErrors(Object? data) {
    if (data is! Map || data['errors'] is! Map) return {};
    final errors = <String, String>{};
    (data['errors'] as Map).forEach((key, value) {
      if (value is Iterable && value.isNotEmpty) {
        errors[key.toString()] = value.first.toString();
      } else if (value != null) {
        errors[key.toString()] = value.toString();
      }
    });
    return errors;
  }

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.kErrorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Widget _buildSuccessDialog(BuildContext dialogContext, String? response) {
    final requestName = switch (_jenisPengajuan) {
      'lupa_keduanya' => 'Lupa absen masuk & pulang',
      'izin' => 'Pengajuan izin',
      _ => 'Pengajuan sakit',
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.kPrimaryDarker.withValues(alpha: 0.2),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.kPrimaryColor, AppColors.kPrimaryDarker],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.32),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Berhasil Dikirim!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    response?.isNotEmpty == true
                        ? response!
                        : 'Pengajuan kamu sudah masuk ke sistem.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE9E8FF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.kPrimaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.event_note_rounded,
                            color: AppColors.kPrimaryColor,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RINGKASAN PENGAJUAN',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppColors.kTextSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                requestName,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppColors.kTextPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_tanggal != null)
                                Text(
                                  _formatDate(_tanggal!),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: AppColors.kTextSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          color: Color(0xFFD99000),
                          size: 19,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Status: Menunggu persetujuan admin. Kamu bisa cek perkembangannya di riwayat absensi.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF795500),
                              fontSize: 11,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Oke, Mengerti',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOrganik = _isOrganik;
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.kBackgroundColor,
        appBar: AppBar(
          title: const Text('Pengajuan Absensi Lampau'),
          backgroundColor: AppColors.kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                _buildSectionTitle('Jenis pengajuan', 'Pilih alasan absensi'),
                const SizedBox(height: 12),
                _buildRequestTypeOptions(),
                const SizedBox(height: 20),
                _buildSectionTitle(
                  'Waktu absensi',
                  'Maksimal 30 hari terakhir',
                ),
                const SizedBox(height: 12),
                _buildCard(
                  child: Column(
                    children: [
                      _buildPicker(
                        label: 'Tanggal absensi',
                        value: _tanggal == null ? null : _formatDate(_tanggal!),
                        error: _fieldErrors['tanggal'],
                        icon: Icons.calendar_month_rounded,
                        onTap: _pickDate,
                      ),
                      if (_jenisPengajuan == 'lupa_keduanya') ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPicker(
                                label: 'Jam masuk',
                                value: _formatTime(_jamMasuk),
                                error: _fieldErrors['jam_masuk'],
                                icon: Icons.login_rounded,
                                onTap: () => _pickTime(checkIn: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPicker(
                                label: 'Jam pulang',
                                value: _formatTime(_jamPulang),
                                error: _fieldErrors['jam_pulang'],
                                icon: Icons.logout_rounded,
                                onTap: () => _pickTime(checkIn: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildInfoStrip(
                          icon: Icons.info_outline_rounded,
                          text:
                              'Jam pulang harus setelah jam masuk dan tidak boleh melewati waktu sekarang.',
                        ),
                      ],
                      if (_jenisPengajuan == 'izin' && isOrganik) ...[
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _jenisIzin,
                          decoration: _inputDecoration(
                            label: 'Jenis cuti',
                            icon: Icons.beach_access_rounded,
                            error: _fieldErrors['jenis_izin'],
                          ),
                          items: _leaveTypes.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                          onChanged: _isSubmitting
                              ? null
                              : (value) => setState(() {
                                  _jenisIzin = value;
                                  _fieldErrors.remove('jenis_izin');
                                }),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Keterangan', 'Ceritakan alasan pengajuan'),
                const SizedBox(height: 12),
                _buildCard(
                  child: TextFormField(
                    controller: _keteranganController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.kTextPrimary,
                    ),
                    decoration:
                        _inputDecoration(
                          label: 'Keterangan',
                          hint:
                              'Tuliskan keterangan dengan jelas (5–500 karakter)',
                          icon: Icons.notes_rounded,
                          error: _fieldErrors['keterangan'],
                        ).copyWith(
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 58),
                            child: Icon(
                              Icons.notes_rounded,
                              color: AppColors.kPrimaryColor,
                            ),
                          ),
                          counterStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.kTextSecondary,
                          ),
                        ),
                    validator: (value) {
                      final length = value?.trim().runes.length ?? 0;
                      if (length < 5 || length > 500) {
                        return 'Keterangan harus 5–500 karakter.';
                      }
                      return null;
                    },
                    onChanged: (_) =>
                        setState(() => _fieldErrors.remove('keterangan')),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle(
                  'Foto bukti',
                  'Wajib • JPG/PNG • Maks. 2 MB',
                ),
                const SizedBox(height: 12),
                _buildPhotoCard(),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      disabledBackgroundColor: AppColors.kPrimaryColor
                          .withValues(alpha: 0.55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 19),
                    label: Text(
                      _isSubmitting
                          ? 'Mengirim pengajuan...'
                          : 'Kirim Pengajuan',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.kPrimaryColor, AppColors.kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajukan absensi tanggal lampau',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Lengkapi detail dan foto bukti. Pengajuan akan diperiksa oleh admin.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.kTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.kTextSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRequestTypeOptions() {
    const options = [
      (
        value: 'lupa_keduanya',
        title: 'Lupa absen',
        subtitle: 'Masuk dan pulang',
        icon: Icons.access_time_filled_rounded,
        color: AppColors.kPrimaryColor,
      ),
      (
        value: 'izin',
        title: 'Izin',
        subtitle: 'Pengajuan izin',
        icon: Icons.event_note_rounded,
        color: AppColors.kPurpleColor,
      ),
      (
        value: 'sakit',
        title: 'Sakit',
        subtitle: 'Pengajuan sakit',
        icon: Icons.health_and_safety_rounded,
        color: AppColors.kErrorColor,
      ),
    ];

    return Column(
      children: options.map((option) {
        final selected = _jenisPengajuan == option.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: _isSubmitting
                  ? null
                  : () => setState(() {
                      _jenisPengajuan = option.value;
                      _fieldErrors.clear();
                    }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? option.color.withValues(alpha: 0.07)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: selected ? option.color : const Color(0xFFE9EAF2),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: option.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(option.icon, color: option.color, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.kTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            option.subtitle,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.kTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? option.color : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_fileBukti == null)
            InkWell(
              onTap: _isSubmitting ? null : _showPhotoOptions,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 23,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD8D9E8),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.kPrimaryColor,
                      size: 34,
                    ),
                    SizedBox(height: 9),
                    Text(
                      'Tambah foto bukti',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.kTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Foto ini hanya untuk diperiksa admin',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.kTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                _fileBukti!,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.kSuccessColor,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _fileBukti!.path.split(Platform.pathSeparator).last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isSubmitting ? null : _showPhotoOptions,
                  child: const Text(
                    'Ganti',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus foto',
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() {
                          _fileBukti = null;
                          _fieldErrors.remove('file_bukti');
                        }),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.kErrorColor,
                  ),
                ),
              ],
            ),
          ],
          if (_fieldErrors['file_bukti'] != null) ...[
            const SizedBox(height: 8),
            Text(
              _fieldErrors['file_bukti']!,
              style: const TextStyle(
                color: AppColors.kErrorColor,
                fontFamily: 'Poppins',
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoStrip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.kPrimaryColor, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.kTextMuted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker({
    required String label,
    required String? value,
    required String? error,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSubmitting ? null : onTap,
      child: InputDecorator(
        decoration: _inputDecoration(label: label, icon: icon, error: error),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? 'Pilih',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
                  color: value == null
                      ? AppColors.kTextSecondary
                      : AppColors.kTextPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.kTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? error,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      prefixIcon: Icon(icon, color: AppColors.kPrimaryColor, size: 20),
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.kTextSecondary,
        fontSize: 12,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: AppColors.kTextSecondary,
        fontSize: 11,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: border(const Color(0xFFE5E7EB)),
      enabledBorder: border(const Color(0xFFE5E7EB)),
      focusedBorder: border(AppColors.kPrimaryColor, width: 1.5),
      errorBorder: border(AppColors.kErrorColor),
      focusedErrorBorder: border(AppColors.kErrorColor, width: 1.5),
    );
  }
}
