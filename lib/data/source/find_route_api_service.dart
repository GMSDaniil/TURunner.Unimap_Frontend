import 'dart:convert';
import 'package:auth_app/core/constants/api_urls.dart';
import 'package:auth_app/core/network/dio_client.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';

const String apiKey = '5658bf81-261b-41fb-9ff2-fedcdf9d5f6f';


class FindRouteApiService {

  //TODO change function type. Return only response. (Check auth_api_service.dart)
  Future<Either<String, List<LatLng>>> getRoute(FindRouteReqParams params) async {

    try {
     var response = await sl<DioClient>().post(
        ApiUrls.findRoute,
        data: params.toMap()
      );
      final data = response.data;
      if (data['paths'] != null && data['paths'].isNotEmpty) {
          String encodedPolyline = data['paths'][0]['points'];
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> points = polylinePoints.decodePolyline(encodedPolyline);
          List<LatLng> routePoints = points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
              
          return Right(routePoints);
      }else {
          return Left("No paths found");
      }
      

    } on DioException catch(e) {
      return Left(e.response!.data['message']);
    }
  }
}


// Future<Either> fetchGames(FetchGamesReqParams request) async {
//     try{
//       final response = await sl<DioClient>().post(
//         ApiUrls.games,
//         data: request.toMap(),
//       );
//       return Right(response);
//     }  on DioException catch (e) {
//       return Left(e.response!.data['message']);
//     }
//   }