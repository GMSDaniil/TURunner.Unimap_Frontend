import 'package:latlong2/latlong.dart';
import 'package:auth_app/domain/entities/building_entity.dart';
import 'package:auth_app/domain/repository/building_repository.dart';

class FindBuildingAtPoint {
  final BuildingRepository repository;
  FindBuildingAtPoint(this.repository);

  Future<BuildingEntity?> call(LatLng point) {
    return repository.findBuildingAt(point);
  } 

  
}