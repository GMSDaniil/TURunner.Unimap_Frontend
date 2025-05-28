import 'package:latlong2/latlong.dart';
import 'package:auth_app/domain/entities/building_entity.dart';

abstract class BuildingRepository {
  Future<List<BuildingEntity>> getBuildings();
  Future<BuildingEntity?> findBuildingAt(LatLng point);
}