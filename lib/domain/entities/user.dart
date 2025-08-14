
import 'package:auth_app/data/models/user_meal_model.dart';
import 'package:auth_app/domain/entities/favourite.dart';

class UserEntity {
  final String email;
  final String username;
  List<UserMealModel> favouriteMeals;
  List<FavouriteEntity> favouritePlaces;

  UserEntity({
    required this.email,
    required this.username,
    this.favouriteMeals = const [],
    this.favouritePlaces = const [],
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      email: json['email'] as String,
      username: json['username'] as String,
      favouriteMeals: (json['favouriteMeals'] as List<dynamic>?)
          ?.map((mealJson) => UserMealModel.fromJson(mealJson as Map<String, dynamic>))
          .toList() ?? [],
      favouritePlaces: (json['favouritePlaces'] as List<dynamic>?)
          ?.map((placeJson) => FavouriteEntity.fromJson(placeJson as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}