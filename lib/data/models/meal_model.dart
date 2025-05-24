import '../../domain/entities/meal.dart';

class MealModel extends MealEntity {
  MealModel({
    required super.name,
    required super.vegan,
    required super.vegetarian,
    required super.prices,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      name: json['name'],
      vegan: json['vegan'],
      vegetarian: json['vegetarian'],
      prices: [
        (json['priceStudent'] as num).toDouble(),
        (json['priceEmployee'] as num).toDouble(),
        (json['priceGast'] as num).toDouble(),
      ],
    );
  }
}
