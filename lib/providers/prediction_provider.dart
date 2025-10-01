import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
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
      nutritionInfo: clearNutrition ? null : (nutritionInfo ?? this.nutritionInfo),
      error: error,
    );
  }
}

class PredictionNotifier extends StateNotifier<PredictionState> {
  final MealDbService _mealDbService;
  final GeminiService _geminiService;
  final Logger _logger = Logger();

  PredictionNotifier(this._mealDbService, this._geminiService)
      : super(PredictionState());

  Future<void> fetchMealInfo(String foodName) async {
    try {
      state = state.copyWith(isLoadingMeal: true, clearMeals: true);

      final meals = await _mealDbService.searchMealByName(foodName);

      state = state.copyWith(
        meals: meals,
        isLoadingMeal: false,
      );
    } catch (e) {
      _logger.e('Error fetching meal info: $e');
      state = state.copyWith(
        isLoadingMeal: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchNutritionInfo(String foodName) async {
    try {
      state = state.copyWith(isLoadingNutrition: true, clearNutrition: true);

      final nutritionInfo = await _geminiService.getNutritionInfo(foodName);

      state = state.copyWith(
        nutritionInfo: nutritionInfo,
        isLoadingNutrition: false,
      );
    } catch (e) {
      _logger.e('Error fetching nutrition info: $e');
      state = state.copyWith(
        isLoadingNutrition: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchAllInfo(String foodName) async {
    await Future.wait([
      fetchMealInfo(foodName),
      fetchNutritionInfo(foodName),
    ]);
  }

  void clearData() {
    state = PredictionState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
