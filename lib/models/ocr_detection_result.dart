class OcrDetectionResult {
  final List<Map<String, dynamic>> objectDetections;
  final List<Map<String, dynamic>> ocrResults;
  final DateTime timestamp;

  OcrDetectionResult({
    required this.objectDetections,
    required this.ocrResults,
    required this.timestamp,
  });

  Map<String, dynamic> get detectionResult =>
      objectDetections.isNotEmpty ? objectDetections.first : {};

  String get ocrText =>
      ocrResults.isNotEmpty ? ocrResults.first['text'] ?? '' : '';
}
