import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/data/models/get_favourites_req_params.dart';
import 'package:auth_app/domain/repository/favourites.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class GetFavouritesUseCase
    implements
        UseCase<Either<String, List<FavouriteEntity>>, GetFavouritesReqParams> {
  @override
  Future<Either<String, List<FavouriteEntity>>> call({
    GetFavouritesReqParams? param,
  }) async {
    if (param == null) return Left("Parameters cannot be null");
    try {
      return await sl<FavouritesRepository>().getFavourites(param);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}
