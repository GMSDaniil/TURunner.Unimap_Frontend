import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:latlong2/latlong.dart';
import 'package:dartz/dartz.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';

class FindRouteUseCase implements UseCase<Either<String, List<LatLng>>, FindRouteReqParams> {
  @override
  //Change function type.
  Future<Either<String, List<LatLng>>> call({FindRouteReqParams? param}) async {
    return await sl<RouteRepository>().findRoute(param!);
  }
}