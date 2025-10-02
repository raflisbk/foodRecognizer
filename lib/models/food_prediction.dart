class FoodPrediction {
  final String label;
  final double confidence;
  final DateTime timestamp;

  FoodPrediction({
    required this.label,
    required this.confidence,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FoodPrediction.fromJson(Map<String, dynamic> json) => FoodPrediction(
    label: json['label'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
