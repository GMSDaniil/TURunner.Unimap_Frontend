import 'dart:convert';
import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/data/models/get_favourites_req_params.dart';
import 'package:auth_app/data/models/add_favourite_req_params.dart';
import 'package:auth_app/data/models/delete_favourite_req_params.dart';
import 'package:auth_app/domain/repository/favourites.dart';
import 'package:auth_app/data/source/favourites_api_service.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:auth_app/data/models/favourite_status_response.dart';

class FavouritesRepositoryImpl implements FavouritesRepository {
  @override
  Future<Either<String, List<FavouriteEntity>>> getFavourites(
    GetFavouritesReqParams params,
  ) async {
    final result = await sl<FavouritesApiService>().getFavourites(
      params.userId,
    );

    return result.fold((errorMessage) => Left(errorMessage), (response) {
      try {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        final favourites = (data as List)
            .map(
              (json) => FavouriteEntity(
                id: json['id'],
                name: json['name'],
                lat: (json['lat'] as num).toDouble(),
                lng: (json['lng'] as num).toDouble(),
                category: json['category'],
              ),
            )
            .toList();
        return Right(favourites);
      } catch (e) {
        return Left('Failed to parse favourites');
      }
    });
  }

  @override
  Future<Either<String, FavouriteStatusResponse>> addFavourite(
    AddFavouriteReqParams params,
  ) async {
    final result = await sl<FavouritesApiService>().addFavourite(
      params.userId,
      params.pointerId,
    );

    return result.fold(
      (errorMessage) => Left(errorMessage),
      (response) {
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final status = FavouriteStatusResponse.fromJson(data);
          return Right(status);
        } catch (e) {
          return Left('Failed to parse addFavourite response');
        }
      },
    );
  }

  @override
  Future<Either<String, FavouriteStatusResponse>> deleteFavourite(
    DeleteFavouriteReqParams params,
  ) async {
    final result = await sl<FavouritesApiService>().deleteFavourite(
      params.userId,
      params.pointerId,
    );

    return result.fold(
      (errorMessage) => Left(errorMessage),
      (response) {
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final status = FavouriteStatusResponse.fromJson(data);
          return Right(status);
        } catch (e) {
          return Left('Failed to parse deleteFavourite response');
        }
      },
    );
  }
}
