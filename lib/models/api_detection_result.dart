class ApiDetectionResult {
  final List<Detection> detections;
  final String annotatedImage;

  ApiDetectionResult({required this.detections, required this.annotatedImage});

  factory ApiDetectionResult.fromJson(Map<String, dynamic> json) {
    var list = json['detections'] as List;
    List<Detection> detectionsList =
        list.map((i) => Detection.fromJson(i)).toList();
    return ApiDetectionResult(
      detections: detectionsList,
      annotatedImage: json['annotated_image'],
    );
  }
}

class Detection {
  final String className;
  final String text;

  Detection({required this.className, required this.text});

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      className: json['class_name'],
      text: json['text'],
    );
  }
}
