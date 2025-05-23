import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:latlong2/latlong.dart';
import 'package:dartz/dartz.dart';
import 'package:auth_app/core/usecase/usecase.dart';

class FindRouteUseCase implements UseCase<Either<String, List<LatLng>>, FindRouteReqParams> {
  final RouteRepository repository;

  FindRouteUseCase(this.repository);

  @override
  Future<Either<String, List<LatLng>>> call({FindRouteReqParams? param}) async {
    return await repository.findRoute(param!);
  }
}