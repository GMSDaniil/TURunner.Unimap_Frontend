import 'package:auth_app/data/models/find_route_response.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:dio/dio.dart';
import 'package:auth_app/data/source/find_route_api_service.dart';
import 'package:auth_app/service_locator.dart';

class RouteRepositoryImpl implements RouteRepository {
  @override
  Future<FindRouteResponse> findRoute(FindRouteReqParams params) async {
    final result = await sl<FindRouteApiService>().getRoute(params);

    try{
      final response = result as Response;
      final routeData = response.data['route'] as Map<String, dynamic>;

      return FindRouteResponse.fromJson(routeData);
    } catch (e) {
      print('Error parsing route data: $e');
      return FindRouteResponse(
        foot: [],
        bus: [],
        scooter: [],
      );
    }
  }
}
