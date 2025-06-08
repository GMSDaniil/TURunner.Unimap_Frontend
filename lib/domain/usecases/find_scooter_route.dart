
import 'package:auth_app/data/models/find_scooter_route_response.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';

class FindScooterRouteUseCase implements UseCase<Either<String, FindScooterRouteResponse>, FindRouteReqParams> {
  @override
  Future<Either<String, FindScooterRouteResponse>> call({FindRouteReqParams? param}) async {
    if (param == null) return Left("Parameters can't be null");

    try {
      return await sl<RouteRepository>().findScooterRoute(param);
    } catch (e) {
      return Left('Unexpected error: ${e.toString()}');
    }
  }
}