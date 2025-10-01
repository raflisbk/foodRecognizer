class NutritionInfo {
  final double calories;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double protein;
  final String servingSize;

  NutritionInfo({
    required this.calories,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.protein,
    this.servingSize = '100g',
  });

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'carbohydrates': carbohydrates,
        'fat': fat,
        'fiber': fiber,
        'protein': protein,
        'servingSize': servingSize,
      };

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        calories: (json['calories'] as num).toDouble(),
        carbohydrates: (json['carbohydrates'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
        fiber: (json['fiber'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        servingSize: json['servingSize'] as String? ?? '100g',
      );
}
