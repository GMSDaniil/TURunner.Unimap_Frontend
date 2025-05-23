import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:latlong2/latlong.dart';
import 'package:dartz/dartz.dart';

abstract class RouteRepository {
  /// Returns either an error message or the list of route points.
  Future<Either<String, List<LatLng>>> findRoute(FindRouteReqParams params);
}