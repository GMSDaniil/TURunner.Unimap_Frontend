
import 'package:auth_app/data/models/pointer.dart';
import 'package:auth_app/domain/entities/building_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:latlong2/latlong.dart';

abstract class PointersRepository {
  Future<Either<String, List<Pointer>>> getPointers();
  Future<List<BuildingEntity>> getBuildings();
  Future<BuildingEntity?> findBuildingAt(LatLng point);
}