import 'package:auth_app/data/models/find_bus_route_response.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class FindBusRouteUseCase implements UseCase<Either<String, List<FindBusRouteResponse>>, FindRouteReqParams> {
  @override
  Future<Either<String, List<FindBusRouteResponse>>> call({FindRouteReqParams? param}) async {
    if (param == null) return Left("Parameters can't be null");

    try {
      return await sl<RouteRepository>().findBusRoute(param);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}