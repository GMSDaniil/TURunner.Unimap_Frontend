
import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';




class FindRouteApiService {
  Future<Either> getRoute(FindRouteReqParams params) async {

    try {
     var response = await sl<DioClient>().post(
        ApiUrls.findRoute,
        data: params.toMap()
      );
      return Right(response);

    } on DioException catch(e) {
      return Left(e.response!.data['message']);
    }
  }
}