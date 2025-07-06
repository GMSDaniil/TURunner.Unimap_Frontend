import 'package:auth_app/data/models/add_favourite_req_params.dart';
import 'package:auth_app/domain/repository/favourites.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
//import 'package:auth_app/data/models/favourite_status_response.dart';

class AddFavouriteUseCase
    implements UseCase<Either<String, void>, AddFavouriteReqParams> {
  @override
  Future<Either<String, void>> call({AddFavouriteReqParams? param}) async {
    if (param == null) return Left("Parameters cannot be null");
    try {
      return await sl<FavouritesRepository>().addFavourite(param);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}
