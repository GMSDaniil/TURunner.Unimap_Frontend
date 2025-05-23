import '../../domain/entities/meal.dart';

class MealModel extends MealEntity {
  MealModel({
    required super.name,
    required super.vegan,
    required super.vegetarian,
    required super.preisStudent,
    required super.preisTeacher,
    required super.preisOther,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      name: json['name'],
      vegan: json['vegan'],
      vegetarian: json['vegetarian'],
      preisStudent: (json['preisStudent'] as num).toDouble(),
      preisTeacher: (json['preisTeacher'] as num).toDouble(),
      preisOther: (json['preisOther'] as num).toDouble(),
    );
  }
}
