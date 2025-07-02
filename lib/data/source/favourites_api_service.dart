import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:auth_app/data/models/add_favourite_req_params.dart';
import 'package:auth_app/data/models/delete_favourite_req_params.dart';

class FavouritesApiService {
  // GET read all favourites for the current user
  Future<Either<String, Response>> getFavourites() async {
    try {
      final url = '${ApiUrls.baseURL}FavoritePlaces';
      final response = await sl<DioClient>().get(url);
      return Right(response);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }

  // POST create a favourite
  Future<Either<String, Response>> addFavourite(
    AddFavouriteReqParams params,
  ) async {
    try {
      final url = '${ApiUrls.baseURL}FavoritePlaces/add';
      final response = await sl<DioClient>().post(url, data: params.toJson());
      return Right(response);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }

  // DELETE a favourite by its id
  Future<Either<String, Response>> deleteFavourite(
    DeleteFavouriteReqParams params,
  ) async {
    try {
      final url = '${ApiUrls.baseURL}FavoritePlaces/${params.favouriteId}';
      final response = await sl<DioClient>().delete(url);
      return Right(response);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }
}
