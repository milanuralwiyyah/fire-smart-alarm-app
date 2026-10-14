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

  double averageTemperature(List<Reading> readings) {
  final recent = readings.take(10).toList();
  if (recent.isEmpty) return 0.0;
  final total = recent.map((r) => r.temperature).reduce((a, b) => a + b);
  return total / recent.length;
}
}