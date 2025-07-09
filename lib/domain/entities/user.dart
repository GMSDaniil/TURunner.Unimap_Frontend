
import 'package:auth_app/data/models/user_meal_model.dart';

class UserEntity {
  final String email;
  final String username;
  List<UserMealModel> favouriteMeals;

  UserEntity({
    required this.email,
    required this.username,
    this.favouriteMeals = const [],
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      email: json['email'] as String,
      username: json['username'] as String,
      favouriteMeals: (json['favouriteMeals'] as List<dynamic>?)
          ?.map((mealJson) => UserMealModel.fromJson(mealJson as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}