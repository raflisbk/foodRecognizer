import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import '../models/meal_detail.dart';

class MealDbService {
  static final Logger _logger = Logger();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.mealDbBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Singleton pattern
  static final MealDbService _instance = MealDbService._internal();
  factory MealDbService() => _instance;
  MealDbService._internal();

  Future<List<MealDetail>> searchMealByName(String name) async {
    try {
      _logger.i('Searching meals for: $name');

      final response = await _dio.get(
        ApiConstants.searchEndpoint,
        queryParameters: {'s': name},
      );

      if (response.statusCode == 200 && response.data != null) {
        final meals = response.data['meals'] as List<dynamic>?;

        if (meals == null || meals.isEmpty) {
          _logger.w('No meals found for: $name');
          return [];
        }

        final mealList = meals
            .map((meal) => MealDetail.fromJson(meal as Map<String, dynamic>))
            .toList();

        _logger.i('Found ${mealList.length} meals');
        return mealList;
      }

      return [];
    } on DioException catch (e) {
      _logger.e('Dio error searching meals: ${e.message}');
      return [];
    } catch (e) {
      _logger.e('Error searching meals: $e');
      return [];
    }
  }

  Future<MealDetail?> getMealById(String id) async {
    try {
      _logger.i('Getting meal by ID: $id');

      final response = await _dio.get(
        '/lookup.php',
        queryParameters: {'i': id},
      );

      if (response.statusCode == 200 && response.data != null) {
        final meals = response.data['meals'] as List<dynamic>?;

        if (meals == null || meals.isEmpty) {
          return null;
        }

        return MealDetail.fromJson(meals[0] as Map<String, dynamic>);
      }

      return null;
    } on DioException catch (e) {
      _logger.e('Dio error getting meal: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Error getting meal: $e');
      return null;
    }
  }
}
