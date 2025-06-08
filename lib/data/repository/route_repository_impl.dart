import 'dart:convert';

import 'package:auth_app/data/models/find_bus_route_response.dart';
import 'package:auth_app/data/models/find_route_response.dart';
import 'package:auth_app/data/models/find_scooter_route_response.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:auth_app/data/source/find_route_api_service.dart';
import 'package:auth_app/service_locator.dart';

class RouteRepositoryImpl implements RouteRepository {
   @override
  Future<Either<String, FindRouteResponse>> findRoute(FindRouteReqParams params) async {
    final result = await sl<FindRouteApiService>().getRoute(params);

    return result.fold(
      // Handle error from API service
      (errorMessage) => Left(errorMessage),

      // Parse success response
      (response) {
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final route = FindRouteResponse.fromJson(data);
          return Right(route);
        } catch (e) {
          print('Error parsing route data: $e');
          return Left('Failed to parse route data');
        }
      },
    );
  }

   @override
  Future<Either<String, FindBusRouteResponse>> findBusRoute(FindRouteReqParams params) async {
    final result = await sl<FindRouteApiService>().getBusRoute(params);

    return result.fold(
      // Handle error from API service
      (errorMessage) => Left(errorMessage),

      // Parse success response
      (response) {
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final route = FindBusRouteResponse.fromJson(data);
          return Right(route);
        } catch (e) {
          print('Error parsing route data: $e');
          return Left('Failed to parse route data');
        }
      },
    );
  }

  @override
  Future<Either<String, FindScooterRouteResponse>> findScooterRoute(FindRouteReqParams params) async {
    final result = await sl<FindRouteApiService>().getScooterRoute(params);

    return result.fold(
      // Handle error from API service
      (errorMessage) => Left(errorMessage),

      // Parse success response
      (response) {
        try {
          final data = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          final route = data is List
              ? FindScooterRouteResponse.fromSegmentsList(data)
              : FindScooterRouteResponse.fromJson(data);
          return Right(route);
        } catch (e) {
          print('Error parsing route data: $e');
          return Left('Failed to parse route data');
        }
      },
    );
  }
}
