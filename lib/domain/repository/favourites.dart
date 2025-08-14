import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/data/models/add_favourite_req_params.dart';
import 'package:auth_app/data/models/delete_favourite_req_params.dart';
import 'package:dartz/dartz.dart';

abstract class FavouritesRepository {
  Future<Either<String, List<FavouriteEntity>>> getFavourites();
  Future<Either<String, String>> addFavourite(AddFavouriteReqParams params);
  Future<Either<String, void>> deleteFavourite(DeleteFavouriteReqParams params);
}
