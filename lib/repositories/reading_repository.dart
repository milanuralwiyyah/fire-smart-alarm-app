import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reading.dart';

class ReadingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Reading>> getReadings() {
    return _firestore
        .collection('fire-activity')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        return Reading(
          deviceId: data['deviceId']?.toString() ?? '',
          smoke: (data['smoke'] ?? 0).toDouble(),
          temperature: (data['temperature'] ?? 0).toDouble(),
          humidity: (data['humidity'] ?? 0).toDouble(),
          status: data['status']?.toString() ?? 'Normal',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  // Varian A: rata-rata suhu 10 data terakhir
  double averageTemperature(List<Reading> readings) {
    final data = readings.take(10).toList();
    if (data.isEmpty) return 0;
    final total = data.fold<double>(0, (sum, r) => sum + r.temperature);
    return total / data.length;
  }

  // Varian B: suhu tertinggi dari 10 data terakhir
  double highestTemperature(List<Reading> readings) {
    final data = readings.take(10).toList();
    if (data.isEmpty) return 0;
    return data.map((r) => r.temperature).reduce((a, b) => a > b ? a : b);
  }

  // Varian C: suhu terendah dari 10 data terakhir
  double lowestTemperature(List<Reading> readings) {
    final data = readings.take(10).toList();
    if (data.isEmpty) return 0;
    return data.map((r) => r.temperature).reduce((a, b) => a < b ? a : b);
  }

  // Varian D: jumlah data berstatus bahaya dari 20 data terakhir
  int dangerCount(List<Reading> readings) {
    return readings.take(20).where((r) {
      final s = r.status.toUpperCase();
      return s == 'DANGER' || s == 'BAHAYA';
    }).length;
  }
}