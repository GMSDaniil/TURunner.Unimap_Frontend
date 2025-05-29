import 'package:auth_app/data/models/find_route_response.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:dartz/dartz.dart';

abstract class RouteRepository {
  Future<Either<String, FindRouteResponse>> findRoute(FindRouteReqParams params);
}