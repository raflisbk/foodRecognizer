import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_theme.dart';
import '../models/nutrition_info.dart';

class NutritionCard extends StatelessWidget {
  final NutritionInfo nutritionInfo;

  const NutritionCard({super.key, required this.nutritionInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.secondaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.secondaryGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Per Serving',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        nutritionInfo.servingSize,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        nutritionInfo.calories.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'kcal',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nutrition details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FadeInUp(
                  delay: const Duration(milliseconds: 50),
                  child: _NutritionItem(
                    icon: Icons.spa,
                    label: 'Carbohydrates',
                    value: nutritionInfo.carbohydrates,
                    unit: 'g',
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _NutritionItem(
                    icon: Icons.fitness_center,
                    label: 'Protein',
                    value: nutritionInfo.protein,
                    unit: 'g',
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  child: _NutritionItem(
                    icon: Icons.water_drop,
                    label: 'Fat',
                    value: nutritionInfo.fat,
                    unit: 'g',
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _NutritionItem(
                    icon: Icons.grain,
                    label: 'Fiber',
                    value: nutritionInfo.fiber,
                    unit: 'g',
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final Color color;

  const _NutritionItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkColor,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
