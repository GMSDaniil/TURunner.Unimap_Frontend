import 'dart:convert';

import 'package:auth_app/data/models/find_bus_route_response.dart';
import 'package:auth_app/data/models/find_route_response.dart';
import 'package:auth_app/data/models/find_scooter_route_response.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:auth_app/data/source/find_route_api_service.dart';
import 'package:auth_app/service_locator.dart';
import 'package:flutter/foundation.dart';

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
  Future<Either<String, List<FindBusRouteResponse>>> findBusRoute(FindRouteReqParams params) async {
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
          
          if (data is List && data.isNotEmpty){
            final firstRoute = data[0];
            final route = FindBusRouteResponse.fromJson(firstRoute);
            final routes = data.map((e) => FindBusRouteResponse.fromJson(e)).toList();
            return Right(routes);
          }else if (data is Map<String, dynamic>) {
            final route = FindBusRouteResponse.fromJson(data);
            return Right([route]);
          } else {
            return Left('Unexpected data format');
          }
          
          // print('=== Bus Route Debug ===');
          // for (int i = 0; i < route.segments.length; i++) {
          //   print('Segment $i:');
          //   for (int j = 0; j < route.segments[i].segments.length; j++) {
          //     final subSegment = route.segments[i].segments[j];
          //     if (subSegment.precisePolyline != null) {
          //       print('  Sub-segment $j (${subSegment.precisePolyline!.length} points):');
          //       final coordinates = subSegment.precisePolyline!
          //           .map((e) => "(${e.latitude}, ${e.longitude})")
          //           .toList();
                
          //       // Print coordinates in chunks of 10
          //       for (int k = 0; k < coordinates.length; k += 10) {
          //         final chunk = coordinates.skip(k).take(10).toList();
          //         print('    Points ${k}-${k + chunk.length - 1}: $chunk');
          //       }
          //     }
          //   }
          // }
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
          final route = FindScooterRouteResponse.fromJson(data);
          return Right(route);
        } catch (e) {
          print('Error parsing route data: $e');
          return Left('Failed to parse route data');
        }
      },
    );
  }
}
