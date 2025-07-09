import 'package:auth_app/data/models/add_favourite_meals_req_params.dart';
import 'package:auth_app/data/models/user_meal_model.dart';
import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/domain/entities/user.dart';
import 'package:auth_app/domain/usecases/add_favourite_meal.dart';
import 'package:auth_app/domain/usecases/delete_favourite_meal.dart';
import 'package:auth_app/service_locator.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  UserEntity? _user;
  List<FavouriteEntity> _favourites = [];
  List<UserMealModel> _favouriteMeals = [];

  UserEntity? get user => _user;
  List<FavouriteEntity> get favourites => _favourites;
  List<UserMealModel> get favouriteMeals => _favouriteMeals;

  void setUser(UserEntity user) {
    _user = user;
    print(user.favouriteMeals);
    _favouriteMeals = List<UserMealModel>.from(user.favouriteMeals ?? []);
    
    notifyListeners();
  }

  void setFavourites(List<FavouriteEntity> favourites) {
    print('✅ setFavourites called with ${favourites.length} items');
    _favourites = favourites;
    notifyListeners();
  }

  void addFavourite(FavouriteEntity favourite) {
    _favourites.add(favourite);
    notifyListeners();
  }

  void deleteFavourite(int placeId) {
    _favourites.removeWhere((f) => f.placeId == placeId);
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _favourites = [];
    _favouriteMeals = [];
    notifyListeners();
  }

  Future<void> addFavoriteMeal(UserMealModel meal) async {
    try {
      String priceString = meal.prices.isNotEmpty
          ? meal.prices.map((price) => price.toString()).join('/')
          : '';
          
      var request = AddFavouriteMealReqParams(
        name: meal.name,
        price: priceString,
        vegan: meal.vegan,
        vegetarian: meal.vegetarian,
      );
      
      final result = await sl<AddFavouriteMealUseCase>().call(param: request);
      
      result.fold(
        (error) => print('[DEBUG] Failed to add favorite meal: $error'),
        (success) {
          meal.id = success;
          
          // ✅ Add to separate list instead of user entity
          if (!_favouriteMeals.any((m) => m.name == meal.name)) {
            _favouriteMeals.add(meal);
            notifyListeners();
          }
        },
      );
    } catch (e) {
      print('[DEBUG] Error adding favorite meal: $e');
    }
  }

  // ✅ Remove favorite meal
  Future<void> removeFavoriteMeal(int id) async {
    try {
      final result = await sl<DeleteFavouriteMealUseCase>().call(param: id);
      
      result.fold(
        (error) => print('[DEBUG] Failed to remove favorite meal: $error'),
        (success) {
          // ✅ Remove from separate list instead of user entity
          _favouriteMeals.removeWhere((meal) => meal.id == id);
          notifyListeners();
        },
      );
    } catch (e) {
      print('[DEBUG] Error removing favorite meal: $e');
    }
  }

  bool isMealFavorited(String mealName) {
    return _favouriteMeals.any((meal) => 
      meal.name.toLowerCase() == mealName.toLowerCase());
  }

  UserMealModel? findFavoriteMealByName(String name) {
    try {
      return _favouriteMeals.firstWhere(
        (meal) => meal.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> removeFavoriteMealByName(String mealName) async {
    final meal = findFavoriteMealByName(mealName);
    if (meal?.id != null) {
      await removeFavoriteMeal(meal!.id!);
    }
  }

  // ✅ Method to sync favorite meals with user entity (if needed)
  void setFavoriteMeals(List<UserMealModel> meals) {
    _favouriteMeals = List<UserMealModel>.from(meals);
    notifyListeners();
  }
}
