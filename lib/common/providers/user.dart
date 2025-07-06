import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/domain/entities/user.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  UserEntity? _user;
  List<FavouriteEntity> _favourites = [];

  UserEntity? get user => _user;
  List<FavouriteEntity> get favourites => _favourites;

  void setUser(UserEntity user) {
    _user = user;
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
    notifyListeners();
  }
}
