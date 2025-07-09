import 'package:auth_app/data/models/add_favourite_meals_req_params.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/domain/repository/mensa.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class AddFavouriteMealUseCase
    implements UseCase<Either<String, int>, AddFavouriteMealReqParams> {
  @override
  Future<Either<String, int>> call({AddFavouriteMealReqParams? param}) async {
    if (param == null) return Left("Parameters cannot be null");
    try {
      return await sl<MensaRepository>().addFavouriteMeal(param);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}
