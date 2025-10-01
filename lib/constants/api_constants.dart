class ApiConstants {
  // MealDB API
  static const String mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const String searchEndpoint = '/search.php';

  // Gemini API - User should add their own key
  static const String geminiApiKey = 'AIzaSyBTPoJstho2_1yucB4p7B7R2l5Wz_x1_gw';

  // Model paths
  static const String modelFileName = 'food_classifier.tflite';
  static const String labelsFileName = 'labels.txt';

  // Firebase ML
  static const String firebaseModelName = 'food_classifier';

  // Inference settings
  static const int inputSize = 224;
  static const double confidenceThreshold = 0.5;
}
