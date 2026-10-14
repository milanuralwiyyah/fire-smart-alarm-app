import 'package:flutter/material.dart';

import '../models/reading.dart';
import '../repositories/reading_repository.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final ReadingRepository _repository = ReadingRepository();

  static const Color _background = Color(0xFFF7F8FC);
  static const Color _primary = Color(0xFF5546A5);
  static const Color _cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFE45151),
              size: 30,
            ),
            SizedBox(width: 8),
            Text(
              'Fire Smart Alarm',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF25243A),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Reading>>(
        stream: _repository.getReadings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Terjadi kesalahan:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final readings = snapshot.data ?? [];

          if (readings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sensors_off_rounded,
                    size: 58,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada data sensor.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final latest = readings.first;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(latest),

                  const SizedBox(height: 30),

                  _sectionTitle(
                    'Data Terbaru',
                    'Pemantauan kondisi sensor',
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(
                          icon: Icons.thermostat_rounded,
                          title: 'Temperature',
                          value:
                              '${latest.temperature.toStringAsFixed(1)} °C',
                          color: const Color(0xFFE87954),
                          background: const Color(0xFFFFEEE8),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSensorCard(
                          icon: Icons.water_drop_rounded,
                          title: 'Humidity',
                          value:
                              '${latest.humidity.toStringAsFixed(1)} %',
                          color: const Color(0xFF3688D8),
                          background: const Color(0xFFEAF4FF),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  _sectionTitle(
                    'Analisis Sensor',
                    'Statistik berdasarkan data tersimpan',
                  ),

                  const SizedBox(height: 16),

                  // TUGAS A: Rata-rata suhu 10 data terakhir
                  _buildStatisticCard(
                    label: 'TUGAS A',
                    title: 'Rata-rata Suhu',
                    subtitle: 'Dari 10 data terakhir',
                    value:
                        '${_repository.averageTemperature(readings).toStringAsFixed(1)} °C',
                    icon: Icons.functions_rounded,
                    color: const Color(0xFF7258C8),
                    background: const Color(0xFFF0ECFF),
                  ),

                  const SizedBox(height: 13),

                  // TUGAS B: Suhu tertinggi 10 data terakhir
                  _buildStatisticCard(
                    label: 'TUGAS B',
                    title: 'Suhu Tertinggi',
                    subtitle: 'Dari 10 data terakhir',
                    value:
                        '${_repository.highestTemperature(readings).toStringAsFixed(1)} °C',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFE47B42),
                    background: const Color(0xFFFFF0E5),
                  ),

                  const SizedBox(height: 13),

                  // TUGAS C: Suhu terendah 10 data terakhir
                  _buildStatisticCard(
                    label: 'TUGAS C',
                    title: 'Suhu Terendah',
                    subtitle: 'Dari 10 data terakhir',
                    value:
                        '${_repository.lowestTemperature(readings).toStringAsFixed(1)} °C',
                    icon: Icons.trending_down_rounded,
                    color: const Color(0xFF2787B9),
                    background: const Color(0xFFE7F5FC),
                  ),

                  const SizedBox(height: 13),

                  // TUGAS D: Jumlah status bahaya 20 data terakhir
                  _buildStatisticCard(
                    label: 'TUGAS D',
                    title: 'Deteksi Bahaya',
                    subtitle: 'Dari 20 data terakhir',
                    value: '${_repository.dangerCount(readings)} data',
                    icon: Icons.gpp_maybe_rounded,
                    color: const Color(0xFFD94D5C),
                    background: const Color(0xFFFFEDEF),
                  ),

                  const SizedBox(height: 30),

                  _buildMq2Card(latest),

                  const SizedBox(height: 20),

                  _buildInfoCard(
                    icon: Icons.memory_rounded,
                    title: 'Device ID',
                    value: latest.deviceId,
                    color: const Color(0xFF7258C8),
                  ),

                  const SizedBox(height: 12),

                  _buildInfoCard(
                    icon: Icons.schedule_rounded,
                    title: 'Last Update',
                    value: _formatDateTime(latest.timestamp),
                    color: const Color(0xFF3688D8),
                  ),

                  const SizedBox(height: 32),

                  _sectionTitle(
                    'Riwayat Sensor',
                    '${readings.length} data tersimpan',
                  ),

                  const SizedBox(height: 16),

                  ...List.generate(
                    readings.length,
                    (index) => _buildHistoryCard(
                      readings[index],
                      index + 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // JUDUL BAGIAN
  // ============================================================

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF25243A),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF89899A),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS SISTEM
  // ============================================================

  Widget _buildStatusCard(Reading reading) {
    final status = reading.status.toUpperCase();

    Color statusColor;
    IconData statusIcon;
    String statusDescription;

    if (status == 'DANGER' || status == 'BAHAYA') {
      statusColor = const Color(0xFFE34852);
      statusIcon = Icons.warning_rounded;
      statusDescription = 'Peringatan! Periksa kondisi lingkungan.';
    } else if (status == 'WARNING' || status == 'WASPADA') {
      statusColor = const Color(0xFFE79A32);
      statusIcon = Icons.warning_amber_rounded;
      statusDescription = 'Kondisi perlu dipantau.';
    } else {
      statusColor = const Color(0xFF32A879);
      statusIcon = Icons.check_circle_rounded;
      statusDescription = 'Sistem dalam kondisi normal.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF0EEFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8E4FA),
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7E4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 48,
              color: Color(0xFFE45151),
            ),
          ),

          const SizedBox(height: 17),

          const Text(
            'STATUS SISTEM',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF77768B),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 23,
                ),
                const SizedBox(width: 9),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            statusDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF77768B),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU SENSOR TERBARU
  // ============================================================

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color background,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 165),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 51,
            height: 51,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              icon,
              size: 29,
              color: color,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF77768B),
            ),
          ),

          const SizedBox(height: 8),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF25243A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU STATISTIK TUGAS A-D
  // ============================================================

  Widget _buildStatisticCard({
    required String label,
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFEEEEF5),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 59,
            height: 59,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: color,
              size: 31,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: color,
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF29283E),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9291A2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MQ-2 SMOKE
  // ============================================================

  Widget _buildMq2Card(Reading reading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF34315E),
            Color(0xFF6257A6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 59,
            height: 59,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.air_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 16),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MQ-2 Smoke',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Pembacaan sensor asap',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            reading.smoke.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMASI PERANGKAT
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEEEEF5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9291A2),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF29283E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RIWAYAT DATA SENSOR
  // ============================================================

  Widget _buildHistoryCard(
    Reading reading,
    int number,
  ) {
    final status = reading.status.toUpperCase();

    Color statusColor;

    if (status == 'DANGER' || status == 'BAHAYA') {
      statusColor = const Color(0xFFE34852);
    } else if (status == 'WARNING' || status == 'WASPADA') {
      statusColor = const Color(0xFFE79A32);
    } else {
      statusColor = const Color(0xFF32A879);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEEEEF5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sensors_rounded,
                  color: _primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Data #$number',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF29283E),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: Color(0xFFEDEDF3),
            ),
          ),

          _historyRow(
            icon: Icons.thermostat_rounded,
            title: 'Temperature',
            value: '${reading.temperature.toStringAsFixed(1)} °C',
          ),

          const SizedBox(height: 13),

          _historyRow(
            icon: Icons.water_drop_rounded,
            title: 'Humidity',
            value: '${reading.humidity.toStringAsFixed(1)} %',
          ),

          const SizedBox(height: 13),

          _historyRow(
            icon: Icons.air_rounded,
            title: 'MQ-2 Smoke',
            value: reading.smoke.toStringAsFixed(0),
          ),

          const SizedBox(height: 13),

          _historyRow(
            icon: Icons.memory_rounded,
            title: 'Device ID',
            value: reading.deviceId,
          ),

          const SizedBox(height: 13),

          _historyRow(
            icon: Icons.access_time_rounded,
            title: 'Waktu',
            value: _formatDateTime(reading.timestamp),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARIS RIWAYAT
  // ============================================================

  Widget _historyRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF89899A),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF77768B),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF29283E),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}