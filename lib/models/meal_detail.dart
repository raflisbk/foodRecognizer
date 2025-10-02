class MealDetail {
  final String id;
  final String name;
  final String? category;
  final String? area;
  final String? instructions;
  final String? thumbnail;
  final List<String> ingredients;
  final List<String> measures;
  final String? youtube;

  MealDetail({
    required this.id,
    required this.name,
    this.category,
    this.area,
    this.instructions,
    this.thumbnail,
    this.ingredients = const [],
    this.measures = const [],
    this.youtube,
  });

  factory MealDetail.fromJson(Map<String, dynamic> json) {
    List<String> ingredients = [];
    List<String> measures = [];

    // Extract ingredients and measures
    for (int i = 1; i <= 20; i++) {
      String? ingredient = json['strIngredient$i'] as String?;
      String? measure = json['strMeasure$i'] as String?;

      if (ingredient != null && ingredient.trim().isNotEmpty) {
        ingredients.add(ingredient.trim());
      }
      if (measure != null && measure.trim().isNotEmpty) {
        measures.add(measure.trim());
      }
    }

    return MealDetail(
      id: json['idMeal'] as String,
      name: json['strMeal'] as String,
      category: json['strCategory'] as String?,
      area: json['strArea'] as String?,
      instructions: json['strInstructions'] as String?,
      thumbnail: json['strMealThumb'] as String?,
      ingredients: ingredients,
      measures: measures,
      youtube: json['strYoutube'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'idMeal': id,
    'strMeal': name,
    'strCategory': category,
    'strArea': area,
    'strInstructions': instructions,
    'strMealThumb': thumbnail,
    'strYoutube': youtube,
  };
}
