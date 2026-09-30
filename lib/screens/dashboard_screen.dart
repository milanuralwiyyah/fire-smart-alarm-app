import 'package:flutter/material.dart';

import '../models/reading.dart';
import '../repositories/reading_repository.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final ReadingRepository _repository = ReadingRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF9F8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Fire Smart Alarm',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: StreamBuilder<List<Reading>>(
        stream: _repository.getReadings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final readings = snapshot.data ?? [];

          if (readings.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data sensor.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final latest = readings.first;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(latest),
                  const SizedBox(height: 32),

                  const Text(
                    'Data Terbaru',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: _buildSensorCard(
                          icon: Icons.thermostat,
                          iconColor: const Color(0xFF9E5148),
                          title: 'Temperature',
                          value:
                              '${latest.temperature.toStringAsFixed(1)} °C',
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: _buildSensorCard(
                          icon: Icons.water_drop,
                          iconColor: const Color(0xFF9E5148),
                          title: 'Humidity',
                          value:
                              '${latest.humidity.toStringAsFixed(1)} %',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  _buildMq2Card(latest),

                  const SizedBox(height: 24),

                  _buildInfoCard(
                    icon: Icons.memory,
                    title: 'Device ID',
                    value: latest.deviceId,
                  ),

                  const SizedBox(height: 12),

                  _buildInfoCard(
                    icon: Icons.access_time,
                    title: 'Last Update',
                    value: _formatDateTime(latest.timestamp),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Riwayat Data Sensor',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '${readings.length} data tersimpan',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black38,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ...List.generate(
                    readings.length,
                    (index) {
                      return _buildHistoryCard(
                        readings[index],
                        index + 1,
                      );
                    },
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
  // STATUS SISTEM
  // ============================================================

  Widget _buildStatusCard(Reading reading) {
    final status = reading.status.toUpperCase();

    Color statusColor;
    IconData statusIcon;

    if (status == 'DANGER') {
      statusColor = Colors.red;
      statusIcon = Icons.warning_rounded;
    } else if (status == 'WARNING') {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 76,
            color: Color(0xFFF44336),
          ),

          const SizedBox(height: 14),

          const Text(
            'STATUS SISTEM',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 14),

          Icon(
            statusIcon,
            size: 43,
            color: statusColor,
          ),

          const SizedBox(height: 8),

          Text(
            status,
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEMPERATURE / HUMIDITY
  // ============================================================

  Widget _buildSensorCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      height: 175,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: iconColor,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MQ-2
  // ============================================================

  Widget _buildMq2Card(Reading reading) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.air,
            size: 48,
            color: Color(0xFF9E5148),
          ),

          const SizedBox(height: 10),

          const Text(
            'MQ-2 Smoke',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            reading.smoke.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DEVICE ID / LAST UPDATE
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 29,
            color: Colors.black54,
          ),

          const SizedBox(width: 18),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RIWAYAT DATA
  // ============================================================

  Widget _buildHistoryCard(
    Reading reading,
    int number,
  ) {
    final status = reading.status.toUpperCase();

    Color statusColor;

    if (status == 'DANGER') {
      statusColor = Colors.red;
    } else if (status == 'WARNING') {
      statusColor = Colors.orange;
    } else {
      statusColor = const Color(0xFF4CAF50);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EE),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Data #$number',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(
            height: 1,
            color: Color(0xFFD8C9C6),
          ),

          const SizedBox(height: 12),

          _historyRow(
            icon: Icons.thermostat,
            title: 'Temperature:',
            value: '${reading.temperature.toStringAsFixed(1)} °C',
          ),

          const SizedBox(height: 10),

          _historyRow(
            icon: Icons.water_drop,
            title: 'Humidity:',
            value: '${reading.humidity.toStringAsFixed(1)} %',
          ),

          const SizedBox(height: 10),

          _historyRow(
            icon: Icons.air,
            title: 'MQ-2:',
            value: reading.smoke.toStringAsFixed(0),
          ),

          const SizedBox(height: 10),

          _historyRow(
            icon: Icons.memory,
            title: 'Device:',
            value: reading.deviceId,
          ),

          const SizedBox(height: 10),

          _historyRow(
            icon: Icons.access_time,
            title: 'Waktu:',
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
          size: 17,
          color: Colors.black87,
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),

        const Spacer(),

        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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