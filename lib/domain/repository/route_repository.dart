import 'package:auth_app/data/models/find_route_response.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';

abstract class RouteRepository {
  Future<FindRouteResponse> findRoute(FindRouteReqParams params);
}