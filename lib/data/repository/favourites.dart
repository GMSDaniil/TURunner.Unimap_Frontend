import 'dart:convert';
import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/data/models/add_favourite_req_params.dart';
import 'package:auth_app/data/models/delete_favourite_req_params.dart';
import 'package:auth_app/domain/repository/favourites.dart';
import 'package:auth_app/data/source/favourites_api_service.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:auth_app/data/models/favourite_response.dart';

class FavouritesRepositoryImpl implements FavouritesRepository {
  @override
  Future<Either<String, List<FavouriteEntity>>> getFavourites() async {
    final result = await sl<FavouritesApiService>().getFavourites();

    return result.fold(
      (errorMessage) {
        return Left(errorMessage);
      },
      (response) {
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final favouriteResponse = FavouriteResponse.fromJson(data);
          return Right(favouriteResponse.favourites);
        } catch (e) {
          return Left('Failed to parse favourites');
        }
      },
    );
  }

  @override
  Future<Either<String, String>> addFavourite(
    AddFavouriteReqParams params,
  ) async {
    // final getResult = await getFavourites();
    // if (getResult.isRight()) {
    //   final favourites = getResult.getOrElse(() => []);
    //   final alreadyExists = favourites.any(
    //     (f) =>
    //         f.name == params.name &&
    //         f.lat == params.latitude &&
    //         f.lng == params.longitude,
    //   );
    //   if (alreadyExists) {
    //     return Left('Building is already in your favourites.');
    //   }
    // }
    final result = await sl<FavouritesApiService>().addFavourite(params);
    return result.fold((errorMessage) => Left(errorMessage), (response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(response.data);
      } else {
        return Left('Failed to add favourite (status: ${response.statusCode})');
      }
    });
  }

  @override
  Future<Either<String, void>> deleteFavourite(
    DeleteFavouriteReqParams params,
  ) async {
    final result = await sl<FavouritesApiService>().deleteFavourite(params);

    return result.fold((errorMessage) => Left(errorMessage), (response) {
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(null);
      } else {
        return Left(
          'Failed to delete favourite (status: ${response.statusCode})',
        );
      }
    });
  }
}
