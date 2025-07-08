import 'package:auth_app/domain/entities/favourite.dart';
import 'package:auth_app/domain/repository/favourites.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class GetFavouritesUseCase
    implements UseCase<Either<String, List<FavouriteEntity>>, void> {
  @override
  Future<Either<String, List<FavouriteEntity>>> call({void param}) async {
    //print('GetFavouritesUseCase called');
    try {
      final result = await sl<FavouritesRepository>().getFavourites();
      //print('GetFavouritesUseCase repository result: $result');
      return result;
    } catch (e) {
      //print('❌ GetFavouritesUseCase exception: $e');
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}
