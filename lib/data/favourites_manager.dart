/*import 'package:auth_app/data/models/pointer.dart';

class FavouritesManager {
  static final FavouritesManager _instance = FavouritesManager._internal();
  factory FavouritesManager() => _instance;
  FavouritesManager._internal();

  final List<Pointer> _favourites = [];

  List<Pointer> get favourites => List.unmodifiable(_favourites);

  void add(Pointer pointer) {
    if (!_favourites.any((p) => p.name == pointer.name)) {
      _favourites.add(pointer);
    }
  }

  void remove(Pointer pointer) {
    _favourites.removeWhere((p) => p.name == pointer.name);
  }
}*/
