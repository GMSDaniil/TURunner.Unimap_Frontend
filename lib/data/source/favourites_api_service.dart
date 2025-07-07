import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/data/source/error_message_extractor.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:auth_app/data/models/add_favourite_req_params.dart';
import 'package:auth_app/data/models/delete_favourite_req_params.dart';

class FavouritesApiService {
  final ErrorMessageExtractor _errorMessageExtractor = ErrorMessageExtractor();
  // GET read all favourites for the current user
  Future<Either<String, Response>> getFavourites() async {
    print('FavouritesApiService.getFavourites called');
    try {
      final url = '${ApiUrls.baseURL}FavoritePlaces';
      print('Calling GET $url');
      final response = await sl<DioClient>().get(url);
      print(
        'FavouritesApiService.getFavourites got response: ${response.data}',
      );
      return Right(response);
    } on DioException catch (e) {
      return Left(_errorMessageExtractor.extractErrorMessage(e.response?.data));
    }
  }

  // POST create a favourite
  Future<Either<String, Response>> addFavourite(
    AddFavouriteReqParams params,
  ) async {
    print('[FAVOURITE][ADD] Params: ${params.toJson()}');
    try {
      final url = '${ApiUrls.baseURL}FavoritePlaces/add';
      print('[FAVOURITE][ADD] POST $url');
      final response = await sl<DioClient>().post(url, data: params.toJson());
      print('[FAVOURITE][ADD] Response: ${response.data}');
      return Right(response);
    } on DioException catch (e) {
      print('[FAVOURITE][ADD][ERROR] ${e.toString()}');
      return Left(_errorMessageExtractor.extractErrorMessage(e.response?.data));
    }
  }

  // DELETE a favourite by its id
  Future<Either<String, Response>> deleteFavourite(
    DeleteFavouriteReqParams params,
  ) async {
    try {
      final url = '${ApiUrls.baseURL}FavoritePlaces/${params.favouriteId}';
      print('[FAVOURITE][DELETE] DELETE $url');
      final response = await sl<DioClient>().delete(url);
      print('[FAVOURITE][DELETE] Response: ${response.data}');
      return Right(response);
    } on DioException catch (e) {
      print('[FAVOURITE][DELETE][ERROR] ${e.toString()}');
      return Left(_errorMessageExtractor.extractErrorMessage(e.response?.data));
    }
  }
}
