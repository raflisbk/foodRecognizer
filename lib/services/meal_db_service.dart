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

  /// Search meals by name with intelligent fuzzy matching
  ///
  /// This method implements a 3-tier search strategy that works for ALL food classifications:
  ///
  /// Example cases:
  /// 1. "Fried chicken" → finds "Kentucky Fried Chicken" (top result)
  /// 2. "Grilled salmon" → finds "Honey Teriyaki Salmon" (top result)
  /// 3. "Chocolate cake" → finds "Chocolate Gateau" (top result)
  ///
  /// Strategy:
  /// - Tier 1: Try exact/partial match with full name
  /// - Tier 2: Search with each word individually and combine results
  /// - Tier 3: Extract main ingredient and search
  ///
  /// Results are ALWAYS sorted by relevance score, with the most relevant match at index 0.
  /// Returns up to 5 results, all sorted from most to least relevant.
  Future<List<MealDetail>> searchMealByName(String name) async {
    try {
      _logger.i('[MealDB] Step 1: Searching meals with full name: $name');

      // First try: exact/partial match
      var response = await _dio.get(
        ApiConstants.searchEndpoint,
        queryParameters: {'s': name},
      );

      if (response.statusCode == 200 && response.data != null) {
        final meals = response.data['meals'] as List<dynamic>?;

        if (meals != null && meals.isNotEmpty) {
          final mealList = meals
              .map((meal) => MealDetail.fromJson(meal as Map<String, dynamic>))
              .toList();

          // Sort by relevance: prioritize meals that contain more keywords from the search
          final sortedMeals = _sortByRelevance(mealList, name);
          _logger.i('[MealDB] Step 1 SUCCESS: Found ${sortedMeals.length} meals with full name');
          _logger.i('[MealDB] Top result (most relevant): ${sortedMeals.first.name}');

          // Log top 3 results if available
          if (sortedMeals.length > 1) {
            _logger.i('[MealDB] Result ranking:');
            for (var i = 0; i < sortedMeals.length && i < 3; i++) {
              _logger.i('[MealDB]   ${i + 1}. ${sortedMeals[i].name}');
            }
          }

          return sortedMeals; // All results sorted by relevance score
        }
      }

      // Step 2: Try searching with each word and combine results
      _logger.i('[MealDB] Step 1 FAILED: No exact match found');
      _logger.i('[MealDB] Step 2: Searching with individual words from: $name');

      final searchWords = name.toLowerCase().split(' ');
      final allMeals = <String, MealDetail>{}; // Use Map to avoid duplicates by meal ID

      for (var word in searchWords) {
        if (word.length < 3) continue; // Skip very short words

        _logger.i('[MealDB] Step 2: Trying search with word: $word');

        try {
          response = await _dio.get(
            ApiConstants.searchEndpoint,
            queryParameters: {'s': word},
          );

          if (response.statusCode == 200 && response.data != null) {
            final meals = response.data['meals'] as List<dynamic>?;

            if (meals != null && meals.isNotEmpty) {
              for (var mealJson in meals) {
                final meal = MealDetail.fromJson(mealJson as Map<String, dynamic>);
                allMeals[meal.id] = meal; // Add to map, automatically handles duplicates
              }
              _logger.i('[MealDB] Step 2: Found ${meals.length} meals with word "$word"');
            }
          }
        } catch (e) {
          _logger.w('[MealDB] Step 2: Failed to search with word "$word": $e');
          continue;
        }
      }

      if (allMeals.isNotEmpty) {
        final mealList = allMeals.values.toList();
        // Sort by relevance to the original search term
        final sortedMeals = _sortByRelevance(mealList, name);
        _logger.i('[MealDB] Step 2 SUCCESS: Found total ${sortedMeals.length} unique meals');
        _logger.i('[MealDB] Top result (most relevant): ${sortedMeals.first.name}');

        // Log top 3 results if available
        if (sortedMeals.length > 1) {
          _logger.i('[MealDB] Result ranking:');
          for (var i = 0; i < sortedMeals.length && i < 3; i++) {
            _logger.i('[MealDB]   ${i + 1}. ${sortedMeals[i].name}');
          }
        }

        return sortedMeals.take(5).toList(); // Return top 5 most relevant, sorted by score
      }

      // Step 3: Final fallback with main ingredient keyword
      _logger.i('[MealDB] Step 2 FAILED: No meals found with individual words');
      _logger.i('[MealDB] Step 3: Extracting main ingredient keyword');
      final bestKeyword = _extractMostRelevantKeyword(name);

      if (bestKeyword != null && !searchWords.contains(bestKeyword)) {
        _logger.i('[MealDB] Step 3: Trying main ingredient: "$bestKeyword"');

        response = await _dio.get(
          ApiConstants.searchEndpoint,
          queryParameters: {'s': bestKeyword},
        );

        if (response.statusCode == 200 && response.data != null) {
          final meals = response.data['meals'] as List<dynamic>?;

          if (meals != null && meals.isNotEmpty) {
            final mealList = meals
                .map((meal) => MealDetail.fromJson(meal as Map<String, dynamic>))
                .toList();

            final sortedMeals = _sortByRelevance(mealList, name);
            _logger.i('[MealDB] Step 3 SUCCESS: Found ${sortedMeals.length} meals with main ingredient');
            _logger.i('[MealDB] Top result (most relevant): ${sortedMeals.first.name}');

            // Log top 3 results if available
            if (sortedMeals.length > 1) {
              _logger.i('[MealDB] Result ranking:');
              for (var i = 0; i < sortedMeals.length && i < 3; i++) {
                _logger.i('[MealDB]   ${i + 1}. ${sortedMeals[i].name}');
              }
            }

            return sortedMeals.take(5).toList(); // Top 5 sorted by relevance
          }
        }

        _logger.w('[MealDB] Step 3 FAILED: No meals found with main ingredient: $bestKeyword');
      }

      _logger.w('[MealDB] FINAL RESULT: No meals found for: $name');
      return [];
    } on DioException catch (e) {
      _logger.e('[MealDB] ERROR: Network error - ${e.message}');
      return [];
    } catch (e) {
      _logger.e('[MealDB] ERROR: Unexpected error - $e');
      return [];
    }
  }

  /// Sort meals by relevance to search term
  /// Prioritizes meals that contain more keywords from the original search
  /// Example: "Fried chicken" will match "Kentucky Fried Chicken" with high score
  List<MealDetail> _sortByRelevance(List<MealDetail> meals, String searchTerm) {
    final searchWords = searchTerm.toLowerCase().split(' ').where((w) => w.length >= 3).toList();

    // Calculate relevance score for each meal
    final mealScores = meals.map((meal) {
      final mealName = meal.name.toLowerCase();
      final mealWords = mealName.split(' ');
      var score = 0;

      // Count how many search words appear in the meal name
      var matchedWords = 0;
      for (var searchWord in searchWords) {
        if (mealName.contains(searchWord)) {
          matchedWords++;
          score += 10; // High base score for word match

          // Bonus if the word appears as a complete word (not just substring)
          if (mealWords.contains(searchWord)) {
            score += 5;
          }
        }
      }

      // Major bonus if ALL search words are found in meal name
      // Example: "fried" AND "chicken" both found in "Kentucky Fried Chicken"
      if (matchedWords == searchWords.length && searchWords.length > 1) {
        score += 20;
      }

      // Bonus for word order proximity
      // Check if search words appear in similar order in meal name
      if (matchedWords >= 2) {
        var lastIndex = -1;
        var inOrder = true;
        for (var searchWord in searchWords) {
          final index = mealName.indexOf(searchWord);
          if (index != -1) {
            if (lastIndex != -1 && index < lastIndex) {
              inOrder = false;
              break;
            }
            lastIndex = index;
          }
        }
        if (inOrder) {
          score += 10; // Bonus for words appearing in correct order
        }
      }

      // Small bonus if meal name contains similar number of words
      final wordCountDiff = (mealWords.length - searchWords.length).abs();
      if (wordCountDiff <= 2) {
        score += 3;
      }

      return {'meal': meal, 'score': score};
    }).toList();

    // Sort by score (descending)
    mealScores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return mealScores.map((item) => item['meal'] as MealDetail).toList();
  }

  /// Extract most relevant keyword from food name for MealDB search
  /// Prioritizes main ingredients over cooking methods
  String? _extractMostRelevantKeyword(String name) {
    final lowerName = name.toLowerCase();
    final words = lowerName.split(' ');

    // Common cooking methods to skip (less relevant for recipe search)
    final cookingMethods = {
      'fried', 'grilled', 'baked', 'roasted', 'steamed', 'boiled',
      'sauteed', 'braised', 'poached', 'smoked', 'crispy', 'spicy',
      'sweet', 'sour', 'hot', 'cold', 'fresh', 'frozen', 'canned'
    };

    // Common stop words to skip
    final stopWords = {
      'with', 'and', 'the', 'or', 'in', 'on', 'at', 'to', 'for'
    };

    // Main ingredient keywords (higher priority)
    final mainIngredients = {
      'chicken', 'beef', 'pork', 'lamb', 'fish', 'salmon', 'tuna',
      'shrimp', 'prawn', 'lobster', 'crab', 'egg', 'tofu', 'pasta',
      'rice', 'noodles', 'bread', 'pizza', 'burger', 'sandwich',
      'salad', 'soup', 'stew', 'curry', 'steak', 'ribs', 'wings',
      'duck', 'turkey', 'bacon', 'sausage', 'cheese', 'chocolate',
      'cake', 'pie', 'cookie', 'pancake', 'waffle', 'donut'
    };

    // Check if any main ingredient exists (highest priority)
    for (var word in words) {
      if (mainIngredients.contains(word)) {
        return word;
      }
    }

    // Filter out cooking methods and stop words, get longest word
    final relevantWords = words.where((word) =>
      word.length > 3 &&
      !cookingMethods.contains(word) &&
      !stopWords.contains(word)
    ).toList();

    if (relevantWords.isEmpty) {
      // Fallback: return longest word if no relevant words found
      return words.reduce((a, b) => a.length > b.length ? a : b);
    }

    // Return the longest relevant word (usually the main ingredient)
    return relevantWords.reduce((a, b) => a.length > b.length ? a : b);
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
