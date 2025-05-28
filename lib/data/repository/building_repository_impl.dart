import 'package:latlong2/latlong.dart';
import 'package:auth_app/domain/entities/building_entity.dart';
import 'package:auth_app/domain/repository/building_repository.dart';
import 'package:auth_app/data/source/building_data_source.dart';
import 'package:auth_app/core/utils/point_in_polygon.dart';

class BuildingRepositoryImpl implements BuildingRepository {
  final BuildingDataSource dataSource;
  List<BuildingEntity>? _cache;

  BuildingRepositoryImpl(this.dataSource);

  @override
  Future<List<BuildingEntity>> getBuildings() async {
    _cache ??= await dataSource.loadBuildings();
    return _cache!;
  }

  @override
  Future<BuildingEntity?> findBuildingAt(LatLng point) async {
    final buildings = await getBuildings();
    for (final building in buildings) {
      if (pointInPolygon(point, building.polygon)) {
        return building;
      }
    }
    return null;
  }
}