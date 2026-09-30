import 'package:flutter/material.dart';

import '../models/reading.dart';

class ReadingCard extends StatelessWidget {
  final Reading reading;

  const ReadingCard({
    super.key,
    required this.reading,
  });

  @override
  Widget build(BuildContext context) {
    final status = reading.status.toUpperCase();

    Color statusColor;
    IconData statusIcon;

    if (status == 'DANGER') {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    } else if (status == 'WARNING') {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Suhu
            _buildReadingRow(
              icon: Icons.thermostat,
              title: 'Suhu',
              value: '${reading.temperature.toStringAsFixed(1)} °C',
            ),

            const SizedBox(height: 10),

            // Kelembapan
            _buildReadingRow(
              icon: Icons.water_drop,
              title: 'Kelembapan',
              value: '${reading.humidity.toStringAsFixed(1)} %',
            ),

            const SizedBox(height: 10),

            // Asap
            _buildReadingRow(
              icon: Icons.cloud,
              title: 'MQ-2',
              value: reading.smoke.toStringAsFixed(0),
            ),

            const SizedBox(height: 10),

            // Device
            _buildReadingRow(
              icon: Icons.memory,
              title: 'Device',
              value: reading.deviceId,
            ),

            const SizedBox(height: 10),

            // Waktu
            _buildReadingRow(
              icon: Icons.access_time,
              title: 'Waktu',
              value: _formatDateTime(reading.timestamp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(
          '$title:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}