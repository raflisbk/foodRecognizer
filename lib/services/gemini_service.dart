import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/api_constants.dart';
import '../models/nutrition_info.dart';
import 'dart:convert';

class GeminiService {
  late final GenerativeModel _model;

  // Singleton pattern
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  Future<NutritionInfo?> getNutritionInfo(String foodName) async {
    try {
      debugPrint('[Gemini] Requesting nutrition info for: $foodName');

      final prompt =
          '''
Provide detailed nutritional information for "$foodName" in JSON format.
The response should ONLY contain a valid JSON object with the following structure:
{
  "calories": <number>,
  "carbohydrates": <number in grams>,
  "fat": <number in grams>,
  "fiber": <number in grams>,
  "protein": <number in grams>,
  "servingSize": "<serving size description>"
}

Important:
- Return ONLY the JSON object, no additional text or explanation
- All numeric values should be for a typical serving size
- Use realistic average values for the food item
- If exact values are unknown, provide reasonable estimates based on similar foods
''';

      final content = [Content.text(prompt)];
      debugPrint('[Gemini] Sending request to Gemini API');
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        debugPrint('[Gemini] ERROR: Empty response from Gemini API');
        debugPrint('[Gemini] Using fallback nutrition data');
        return _getFallbackNutrition(foodName);
      }

      debugPrint('[Gemini] Response received, parsing JSON data');

      // Extract JSON from response
      String jsonText = response.text!.trim();

      // Remove markdown code blocks if present
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      final jsonData = json.decode(jsonText) as Map<String, dynamic>;
      final nutritionInfo = NutritionInfo.fromJson(jsonData);

      debugPrint('[Gemini] SUCCESS: Nutrition info retrieved successfully');
      debugPrint('[Gemini] Calories: ${nutritionInfo.calories}');
      return nutritionInfo;
    } catch (e) {
      debugPrint('[Gemini] ERROR: Failed to get nutrition info - $e');
      debugPrint('[Gemini] Using fallback nutrition data');
      return _getFallbackNutrition(foodName);
    }
  }

  // Fallback nutrition data when API fails
  NutritionInfo _getFallbackNutrition(String foodName) {
    // Provide generic nutrition info as fallback
    return NutritionInfo(
      calories: 200,
      carbohydrates: 25,
      fat: 8,
      fiber: 3,
      protein: 10,
      servingSize: '100g (estimated)',
    );
  }

  Future<String?> getFoodDescription(String foodName) async {
    try {
      debugPrint('[Gemini] Requesting food description for: $foodName');
      final prompt =
          '''
Provide a brief, interesting description of "$foodName" in 2-3 sentences.
Include its origin, key ingredients, or cultural significance.
Keep it concise and engaging.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      debugPrint('[Gemini] Food description retrieved successfully');
      return response.text;
    } catch (e) {
      debugPrint('[Gemini] ERROR: Failed to get food description - $e');
      return null;
    }
  }
}
