import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class FavouritesApiService {
  Future<Either<String, Response>> getFavourites(String userId) async {
    try {
      final url = '${ApiUrls.baseURL}favourites/$userId';
      final response = await sl<DioClient>().get(url);
      return Right(response);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }

  Future<Either<String, Response>> addFavourite(
    String userId,
    String pointerId,
  ) async {
    try {
      final url = '${ApiUrls.baseURL}favourites/$userId';
      final response = await sl<DioClient>().post(
        url,
        data: {'pointerId': pointerId},
      );
      return Right(response);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }

  Future<Either<String, Response>> deleteFavourite(
    String userId,
    String pointerId,
  ) async {
    try {
      final url = '${ApiUrls.baseURL}favourites/$userId';
      final response = await sl<DioClient>().delete(
        url,
        data: {'pointerId': pointerId},
      );
      return Right(response);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? e.message ?? 'Unknown error');
    }
  }
}
