class Reading {
  final String deviceId;
  final double smoke;
  final double temperature;
  final double humidity;
  final String status;
  final DateTime timestamp;

  Reading({
    required this.deviceId,
    required this.smoke,
    required this.temperature,
    required this.humidity,
    required this.status,
    required this.timestamp,
  });
}