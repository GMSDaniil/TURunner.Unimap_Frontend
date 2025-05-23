import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/data/source/find_route_api_service.dart';

class RouteRepositoryImpl implements RouteRepository {
  final FindRouteApiService apiService;

  RouteRepositoryImpl({required this.apiService});

  @override
  Future<Either<String, List<LatLng>>> findRoute(FindRouteReqParams params) async {
    return await apiService.getRoute(
      startLat: params.startLat,
      startLon: params.startLon,
      endLat: params.endLat,
      endLon: params.endLon,
      profile: params.profile,
    );
  }
}