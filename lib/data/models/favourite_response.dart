import 'package:auth_app/domain/entities/favourite.dart';

class FavouriteResponse {
  final List<FavouriteEntity> favourites;

  FavouriteResponse({required this.favourites});

  factory FavouriteResponse.fromJson(dynamic json) {
    return FavouriteResponse(
      favourites: (json as List)
          .map(
            (e) => FavouriteEntity(
              placeId: e['placeId'] ?? 0,
              name: e['name'] ?? 'Unnamed',
              lat: (e['latitude'] as num).toDouble(),
              lng: (e['longitude'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}
