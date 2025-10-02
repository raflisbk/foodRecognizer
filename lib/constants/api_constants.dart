import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // MealDB API
  static const String mealDbBaseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const String searchEndpoint = '/search.php';

  // Gemini API - Loaded from .env file
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Model paths
  static const String modelFileName = 'food_classifier.tflite';
  static const String labelsFileName = 'labels.txt';

  // Firebase ML
  static const String firebaseModelName = 'food_classifier';

  // Inference settings
  static const int inputSize = 224;
  static const double confidenceThreshold = 0.6;
}
