import 'package:auth_app/data/models/findroute_req_params.dart';
import 'package:auth_app/domain/repository/route_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/data/source/find_route_api_service.dart';
import 'package:auth_app/service_locator.dart';

class RouteRepositoryImpl implements RouteRepository {
  @override
  //change function type. Function should return a class defined by you FindRouteResponse. Parse output of getRoute() function to this FindRouteResponse and return it. Stick with auth.dart (Check auth.dart)
  Future<Either<String, List<LatLng>>> findRoute(FindRouteReqParams params) async {
    return await sl<FindRouteApiService>().getRoute(params);
  }
}


// @override
//   Future<Either<Left, FetchGamesResult>> getGames({
//     FetchGamesReqParams ? params,
//   }) async {
//     params ??= FetchGamesReqParams(
//         search: '',
//         page: 1,
//         pageSize: 10,
//       );
//     final result = await sl<GameApiService>().fetchGames(params);
//     return result.fold(
//       (error) => Left(error),
//       (data) {
//         final response = data as Response;
//         final games = (response.data['games'] as List)
//             .map((json) => Game.fromJson(json))
//             .toList();
//         final totalGames = response.data['totalGames'] as int;
//         return Right(FetchGamesResult(games: games, totalGames: totalGames));
//       },
//     );
//   }