import 'package:auth_app/data/models/add_favourite_meals_req_params.dart';
import 'package:auth_app/data/models/get_menu_req_params.dart';
import 'package:auth_app/data/models/mensa_menu_response.dart';
import 'package:dartz/dartz.dart';

abstract class MensaRepository {
  Future<Either<String, MensaMenuResponse>> getMensaMenu(
    GetMenuReqParams params,
  );

  Future<Either<String, int>> addFavouriteMeal(
    AddFavouriteMealReqParams params,
  );
  Future<Either<String, void>> deleteFavouriteMeal(int mealId);
}
