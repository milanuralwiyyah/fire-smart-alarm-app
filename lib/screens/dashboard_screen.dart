import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reading.dart';
import '../repositories/reading_repository.dart';

const Color _background = Color(0xFFFFF9F8);
const Color _cardColor = Color(0xFFFFF0EE);
const Color _accent = Color(0xFF9E5148);

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final ReadingRepository _repository = ReadingRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
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
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          if (snapshot.hasError) {
            return _message(
              'Data tidak dapat dibaca',
              'Periksa koneksi internet dan pengaturan Firebase.\n${snapshot.error}',
            );
          }

          final readings = snapshot.data ?? [];
          if (readings.isEmpty) {
            return _message(
              'Belum ada data sensor',
              'Data dari Firebase akan tampil di halaman ini.',
            );
          }

          final latest = readings.first;
          final trend = readings.take(20).toList().reversed.toList();

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Dashboard Sensor'),
                      const SizedBox(height: 14),
                     _buildStatusCard(latest),
                      const SizedBox(height: 14),

                      const _AlarmControlCard(),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: _buildSensorCard(
                              icon: Icons.thermostat,
                              title: 'Temperature',
                              value:
                                  '${latest.temperature.toStringAsFixed(1)} °C',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSensorCard(
                              icon: Icons.water_drop,
                              title: 'Humidity',
                              value:
                                  '${latest.humidity.toStringAsFixed(1)} %',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildMq2Card(latest),
                      const SizedBox(height: 14),
                      _buildInfoCard(
                        icon: Icons.memory,
                        title: 'Device ID',
                        value: latest.deviceId,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoCard(
                        icon: Icons.access_time,
                        title: 'Last Update',
                        value: _formatDateTime(latest.timestamp),
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Tren 20 data terakhir'),
                      const SizedBox(height: 12),
                      _buildChartCard(trend, height: 175),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => HistoryScreen(
                                  repository: _repository,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history),
                          label: const Text(
                            'Lihat Riwayat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
        },
      ),
    );
  }
}


class _AlarmControlCard extends StatefulWidget {
  const _AlarmControlCard();

  @override
  State<_AlarmControlCard> createState() =>
      _AlarmControlCardState();
}

class _AlarmControlCardState extends State<_AlarmControlCard> {
  final DocumentReference<Map<String, dynamic>> _controlRef =
      FirebaseFirestore.instance
          .collection('alarm-control')
          .doc('esp32-lab');

  bool _isUpdating = false;

  Future<void> _setAlarm(bool enabled) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      await _controlRef.update({
        'alarmEnabled': enabled,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Alarm berhasil diaktifkan.'
                : 'Alarm dibungkam. Periksa kondisi secara langsung.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah kontrol alarm: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _controlRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Kontrol alarm tidak dapat dibaca dari Firebase.',
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Memuat kontrol alarm...'),
            ),
          );
        }

        final data = snapshot.data!.data()!;
        final enabled = data['alarmEnabled'] as bool? ?? true;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0EE),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kontrol Alarm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    enabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: enabled
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF9E5148),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      enabled
                          ? 'Alarm aktif'
                          : 'Alarm dibungkam',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating
                      ? null
                      : () => _setAlarm(!enabled),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9E5148),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          enabled
                              ? Icons.notifications_off
                              : Icons.notifications_active,
                        ),
                  label: Text(
                    _isUpdating
                        ? 'Menyimpan...'
                        : enabled
                            ? 'Mute Alarm'
                            : 'Aktifkan Alarm',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Membungkam alarm tidak berarti kondisi sudah aman. '
                'Status sensor tetap dipantau.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.repository});

  final ReadingRepository repository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedCount = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Riwayat Suhu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: StreamBuilder<List<Reading>>(
        stream: widget.repository.getReadings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          if (snapshot.hasError) {
            return _message(
              'Riwayat tidak dapat dibaca',
              'Periksa koneksi internet dan pengaturan Firebase.\n${snapshot.error}',
            );
          }

          final allReadings = snapshot.data ?? [];
          if (allReadings.isEmpty) {
            return _message(
              'Belum ada riwayat',
              'Data sensor akan tampil setelah tersedia di Firebase.',
            );
          }

          final readings = allReadings.take(_selectedCount).toList();
          final chartReadings = readings.reversed.toList();

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                  children: [
                    _sectionTitle('Pilih jumlah data'),
                    const SizedBox(height: 12),
                    Row(
                      children: [20, 50, 100].map((count) {
                        final selected = _selectedCount == count;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: count == 100 ? 0 : 10,
                            ),
                            child: ChoiceChip(
                              label: Center(child: Text('$count')),
                              selected: selected,
                              showCheckmark: false,
                              selectedColor: _accent,
                              backgroundColor: _cardColor,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide.none,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedCount = count);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    _buildChartCard(chartReadings, height: 220),
                    const SizedBox(height: 24),
                    _sectionTitle('Daftar riwayat (${readings.length} data)'),
                    const SizedBox(height: 12),
                    ...readings.asMap().entries.map(
                      (entry) => _buildHistoryCard(
                        entry.value,
                        entry.key + 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _sectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
  );
}

Widget _message(String title, String subtitle) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sensors, size: 48, color: _accent),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

Widget _buildStatusCard(Reading reading) {
  final status = reading.status.toUpperCase();
  final statusColor = _statusColor(status);
  final statusIcon = status == 'DANGER'
      ? Icons.warning_rounded
      : status == 'WARNING'
          ? Icons.warning_amber_rounded
          : Icons.check_circle;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        const Icon(
          Icons.local_fire_department,
          size: 58,
          color: Color(0xFFF44336),
        ),
        const SizedBox(height: 10),
        const Text(
          'STATUS SISTEM',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Icon(statusIcon, size: 38, color: statusColor),
        const SizedBox(height: 6),
        Text(
          _statusLabel(status),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: statusColor,
          ),
        ),
      ],
    ),
  );
}

Widget _buildSensorCard({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 150),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(17),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: _accent),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMq2Card(Reading reading) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(17),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.air,
          size: 38,
          color: _accent,
        ),
        const SizedBox(height: 10),
        const Text(
          'MQ-2 Smoke',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          reading.smoke.toStringAsFixed(0),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoCard({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, size: 26, color: Colors.black54),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Colors.black45),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildChartCard(List<Reading> readings, {required double height}) {
  final labels = readings.isEmpty
      ? <String>[]
      : <String>[
          _formatTime(readings.first.timestamp),
          if (readings.length > 2)
            _formatTime(readings[readings.length ~/ 2].timestamp),
          if (readings.length > 1) _formatTime(readings.last.timestamp),
        ];

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    decoration: BoxDecoration(
      color: _cardColor,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suhu (°C)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          width: double.infinity,
          child: readings.length < 2
              ? const Center(
                  child: Text(
                    'Grafik memerlukan minimal 2 data.',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                )
              : CustomPaint(
                  painter: _TemperatureChartPainter(
                    readings.map((r) => r.temperature).toList(),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (label) => Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _TemperatureChartPainter extends CustomPainter {
  _TemperatureChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.isEmpty) return;

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.1
        ? 1.0
        : maxValue - minValue;
    const padding = 12.0;
    final chartHeight = size.height - padding * 2;

    final gridPaint = Paint()
      ..color = const Color(0xFFD8C9C6)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = padding + chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y =
          padding + chartHeight * (1 - (values[i] - minValue) / range);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = _accent
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TemperatureChartPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

Widget _buildHistoryCard(Reading reading, int number) {
  final status = reading.status.toUpperCase();
  final statusColor = _statusColor(status);

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: _cardColor,
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
            Expanded(
              child: Text(
                'Data #$number',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel(status),
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
        const Divider(height: 1, color: Color(0xFFD8C9C6)),
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
          icon: Icons.access_time,
          title: 'Waktu:',
          value: _formatDateTime(reading.timestamp),
        ),
      ],
    ),
  );
}


Widget _historyRow({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Row(
    children: [
      SizedBox(
        width: 24,
        child: Icon(
          icon,
          size: 17,
          color: Colors.black87,
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 115,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    ],
  );
}

Color _statusColor(String status) {
  if (status == 'DANGER' || status == 'BAHAYA') return Colors.red;
  if (status == 'WARNING' || status == 'WASPADA') return Colors.orange;
  return const Color(0xFF4CAF50);
}

String _statusLabel(String status) {
  if (status == 'DANGER' || status == 'BAHAYA') return 'Bahaya';
  if (status == 'WARNING' || status == 'WASPADA') return 'Waspada';
  return 'Normal';
}

String _formatDateTime(DateTime dateTime) {
  return '${dateTime.day.toString().padLeft(2, '0')}/'
      '${dateTime.month.toString().padLeft(2, '0')}/'
      '${dateTime.year} '
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}:'
      '${dateTime.second.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}.'
      '${dateTime.minute.toString().padLeft(2, '0')}';
}