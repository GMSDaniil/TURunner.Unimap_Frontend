
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/domain/repository/mensa.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class DeleteFavouriteMealUseCase
    implements UseCase<Either<String, void>, int> {
  @override
  Future<Either<String, void>> call({int? param}) async {
    if (param == null) return Left("Parameters cannot be null");
    try {
      return await sl<MensaRepository>().deleteFavouriteMeal(param);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}
