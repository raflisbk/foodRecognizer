import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_detail.dart';
import '../models/nutrition_info.dart';
import '../services/meal_db_service.dart';
import '../services/gemini_service.dart';

final mealDbServiceProvider = Provider<MealDbService>((ref) {
  return MealDbService();
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final predictionProvider =
    StateNotifierProvider<PredictionNotifier, PredictionState>((ref) {
      return PredictionNotifier(
        ref.read(mealDbServiceProvider),
        ref.read(geminiServiceProvider),
      );
    });

class PredictionState {
  final bool isLoadingMeal;
  final bool isLoadingNutrition;
  final List<MealDetail> meals;
  final NutritionInfo? nutritionInfo;
  final String? error;

  PredictionState({
    this.isLoadingMeal = false,
    this.isLoadingNutrition = false,
    this.meals = const [],
    this.nutritionInfo,
    this.error,
  });

  PredictionState copyWith({
    bool? isLoadingMeal,
    bool? isLoadingNutrition,
    List<MealDetail>? meals,
    NutritionInfo? nutritionInfo,
    String? error,
    bool clearMeals = false,
    bool clearNutrition = false,
  }) {
    return PredictionState(
      isLoadingMeal: isLoadingMeal ?? this.isLoadingMeal,
      isLoadingNutrition: isLoadingNutrition ?? this.isLoadingNutrition,
      meals: clearMeals ? [] : (meals ?? this.meals),
      nutritionInfo: clearNutrition
          ? null
          : (nutritionInfo ?? this.nutritionInfo),
      error: error,
    );
  }
}

class PredictionNotifier extends StateNotifier<PredictionState> {
  final MealDbService _mealDbService;
  final GeminiService _geminiService;

  PredictionNotifier(this._mealDbService, this._geminiService)
    : super(PredictionState());

  Future<void> fetchMealInfo(String foodName) async {
    try {
      debugPrint('[PredictionProvider] Fetching meal info for: $foodName');
      state = state.copyWith(isLoadingMeal: true, clearMeals: true);

      final meals = await _mealDbService.searchMealByName(foodName);

      debugPrint(
        '[PredictionProvider] Meal info fetched successfully: ${meals.length} meals found',
      );
      state = state.copyWith(meals: meals, isLoadingMeal: false);
    } catch (e) {
      debugPrint('[PredictionProvider] ERROR: Failed to fetch meal info - $e');
      state = state.copyWith(isLoadingMeal: false, error: e.toString());
    }
  }

  Future<void> fetchNutritionInfo(String foodName) async {
    try {
      debugPrint('[PredictionProvider] Fetching nutrition info for: $foodName');
      state = state.copyWith(isLoadingNutrition: true, clearNutrition: true);

      final nutritionInfo = await _geminiService.getNutritionInfo(foodName);

      if (nutritionInfo != null) {
        debugPrint(
          '[PredictionProvider] Nutrition info fetched successfully: ${nutritionInfo.calories} cal',
        );
      } else {
        debugPrint('[PredictionProvider] WARNING: Nutrition info is null');
      }
      state = state.copyWith(
        nutritionInfo: nutritionInfo,
        isLoadingNutrition: false,
      );
    } catch (e) {
      debugPrint(
        '[PredictionProvider] ERROR: Failed to fetch nutrition info - $e',
      );
      state = state.copyWith(isLoadingNutrition: false, error: e.toString());
    }
  }

  Future<void> fetchAllInfo(String foodName) async {
    debugPrint(
      '[PredictionProvider] Fetching all info (meal + nutrition) for: $foodName',
    );
    await Future.wait([fetchMealInfo(foodName), fetchNutritionInfo(foodName)]);
    debugPrint('[PredictionProvider] All info fetched successfully');
  }

  void clearData() {
    debugPrint('[PredictionProvider] Clearing all prediction data');
    state = PredictionState();
  }

  void clearError() {
    debugPrint('[PredictionProvider] Clearing error state');
    state = state.copyWith(error: null);
  }
}
