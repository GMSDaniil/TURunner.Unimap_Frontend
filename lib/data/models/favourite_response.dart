import 'package:auth_app/domain/entities/favourite.dart';

class FavouriteResponse {
  final List<FavouriteEntity> favourites;

  FavouriteResponse({required this.favourites});

  factory FavouriteResponse.fromJson(Map<String, dynamic> json) {
    return FavouriteResponse(
      favourites: (json['favourites'] as List)
          .map(
            (e) => FavouriteEntity(
              id: e['id'],
              name: e['name'],
              lat: (e['lat'] as num).toDouble(),
              lng: (e['lng'] as num).toDouble(),
              //category: e['category'],
            ),
          )
          .toList(),
    );
  }
}
