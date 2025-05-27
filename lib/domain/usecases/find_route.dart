import 'package:auth_app/data/models/find_route_response.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/core/usecase/usecase.dart';
import 'package:auth_app/service_locator.dart';

class FindRouteUseCase implements UseCase<FindRouteResponse, FindRouteReqParams> {
  @override
  Future<FindRouteResponse> call({FindRouteReqParams? param}) async {
    return await sl<RouteRepository>().findRoute(param!);
  }
}