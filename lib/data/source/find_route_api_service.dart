
import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';




class FindRouteApiService {
  Future<Either<String, Response>> getRoute(FindRouteReqParams params) async {
    try {
      final response = await sl<DioClient>().get(
        ApiUrls.findRoute,
        queryParameters: params.toMap(),
      );

      if (response.statusCode != 200) {
        return Left('Failed to fetch route data');
      }

      return Right(response);

    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Unknown error occurred';
      return Left(message);
    } catch (e) {
      return Left('Unexpected error occurred');
    }
  }


  Future<Either<String, Response>> getBusRoute(FindRouteReqParams params) async {
    try {
      final response = await sl<DioClient>().get(
        ApiUrls.findBusRoute,
        queryParameters: params.toMap(),
      );

      if (response.statusCode != 200) {
        return Left('Failed to fetch route data');
      }

      return Right(response);

    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Unknown error occurred';
      return Left(message);
    } catch (e) {
      return Left('Unexpected error occurred');
    }
  }
}
