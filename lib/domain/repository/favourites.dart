import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/data/models/get_favourites_req_params.dart';
import 'package:auth_app/data/models/add_favourite_req_params.dart';
import 'package:auth_app/data/models/delete_favourite_req_params.dart';
import 'package:dartz/dartz.dart';
import 'package:auth_app/data/models/favourite_status_response.dart';

abstract class FavouritesRepository {
  Future<Either<String, List<FavouriteEntity>>> getFavourites(
    GetFavouritesReqParams params,
  );
  Future<Either<String, FavouriteStatusResponse>> addFavourite(
    AddFavouriteReqParams params,
  );
  Future<Either<String, FavouriteStatusResponse>> deleteFavourite(
    DeleteFavouriteReqParams params,
  );
}
