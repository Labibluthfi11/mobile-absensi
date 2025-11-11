import 'package:flutter/material.dart';
import 'package:absensi_app/models/absensi_model.dart';

class SalaryInfoCard extends StatelessWidget {
  final Absensi absensi;

  const SalaryInfoCard({Key? key, required this.absensi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hanya tampilkan jika ada data gaji
    if (absensi.baseSalary == null) {
      return const SizedBox.shrink();
    }

    final bool isLate = (absensi.latePenalty ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLate
              ? [Colors.orange.shade50, Colors.red.shade50]
              : [Colors.green.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isLate ? Icons.warning_amber_rounded : Icons.payments_rounded,
                color: isLate ? Colors.orange.shade700 : Colors.green.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Informasi Gaji Harian',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),

          // Gaji Pokok
          _buildSalaryRow(
            label: 'Gaji Pokok',
            value: absensi.formattedBaseSalary ?? 'Rp 0',
            icon: Icons.account_balance_wallet,
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 8),

          // Potongan Keterlambatan
          if (isLate) ...[
            _buildSalaryRow(
              label: 'Potongan Telat (${absensi.roundedLateMinutes ?? 0} menit)',
              value: '- ${absensi.formattedLatePenalty ?? "Rp 0"}',
              icon: Icons.remove_circle_outline,
              color: Colors.red.shade600,
              isDeduction: true,
            ),
            const SizedBox(height: 8),
          ],

          // Divider
          const Divider(height: 16, thickness: 1),
          const SizedBox(height: 4),

          // Gaji Bersih
          _buildSalaryRow(
            label: 'Gaji Bersih',
            value: absensi.formattedFinalSalary ?? 'Rp 0',
            icon: Icons.monetization_on,
            color: Colors.blue.shade700,
            isFinal: true,
          ),

          // Info Tambahan
          if (isLate) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keterlambatan aktual: ${absensi.lateDurationText ?? "-"}\n'
                      'Pembulatan potongan: ${absensi.roundedLateMinutes ?? 0} menit',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalaryRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isDeduction = false,
    bool isFinal = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isFinal ? 16 : 14,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isFinal ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: isDeduction ? Colors.red.shade700 : 
                   isFinal ? Colors.blue.shade700 : 
                   Colors.green.shade700,
          ),
        ),
      ],
    );
  }
}