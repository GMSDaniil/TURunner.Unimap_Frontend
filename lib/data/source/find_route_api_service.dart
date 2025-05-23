import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';

class FindRouteApiService {
  // You can use Dio or http; here we use Dio.
  final Dio dio;

  FindRouteApiService(this.dio);

  /// Calls GraphHopper Directions API and returns the decoded route as a list of LatLng
  Future<Either<String, List<LatLng>>> getRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String profile = 'foot',
  }) async {
    // Use your GraphHopper API key:
    const String apiKey = '5658bf81-261b-41fb-9ff2-fedcdf9d5f6f';
    final String url =
        'https://graphhopper.com/api/1/route?point=$startLat,$startLon&point=$endLat,$endLon&profile=$profile&locale=en&key=$apiKey&points_encoded=true';
    try {
      final Response response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['paths'] != null && data['paths'].isNotEmpty) {
          String encodedPolyline = data['paths'][0]['points'];
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> points = polylinePoints.decodePolyline(encodedPolyline);
          List<LatLng> routePoints = points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          return Right(routePoints);
        } else {
          return Left("No paths found");
        }
      } else {
        return Left("Failed to fetch route: ${response.statusCode}");
      }
    } on DioException catch (e) {
      return Left(e.message ?? "Error occurred");
    }
  }
}