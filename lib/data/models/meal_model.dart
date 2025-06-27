import '../../domain/entities/meal.dart';

class MealModel extends MealEntity {
  MealModel({
    required super.name,
    required super.vegan,
    required super.vegetarian,
    required super.prices,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    // Price as String, z.B. "1.80 / 2.50 / 3.20"
    final priceString = json['price'] as String? ?? '';
    final prices = priceString
        .split('/')
        .map((s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0.0)
        .toList();

    return MealModel(
      name: json['name'] ?? '',
      vegan: json['vegan'] ?? false,
      vegetarian: json['vegetarian'] ?? false,
      prices: prices,
    );
  }
}
