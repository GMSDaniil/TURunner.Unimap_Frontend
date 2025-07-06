import 'package:auth_app/data/models/delete_favourite_req_params.dart';
import 'package:auth_app/domain/repository/favourites.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class DeleteFavouriteUseCase
    implements UseCase<Either<String, void>, DeleteFavouriteReqParams> {
  @override
  Future<Either<String, void>> call({DeleteFavouriteReqParams? param}) async {
    if (param == null) return Left("Parameters cannot be null");
    try {
      return await sl<FavouritesRepository>().deleteFavourite(param);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}
