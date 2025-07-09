import 'package:auth_app/domain/entities/meal.dart';

class UserMealModel extends MealEntity{
  int id;
  UserMealModel({
    required this.id,
    required super.name,
    required super.vegan,
    required super.vegetarian,
    required super.prices,
  });

  factory UserMealModel.fromJson(Map<String, dynamic> json) {
    // Price as String, z.B. "1.80 / 2.50 / 3.20"
    final priceString = json['mealPrice'] as String? ?? '';
    final prices = priceString
        .split('/')
        .map((s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0.0)
        .toList();

    return UserMealModel(
      id: json['id'] as int? ?? 0,
      name: json['mealName'] ?? '',
      vegan: json['vegan'] ?? false,
      vegetarian: json['vegetarian'] ?? false,
      prices: prices,
    );
  }
}