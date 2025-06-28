import 'package:auth_app/core/utils/point_in_polygon.dart';
import 'package:auth_app/data/source/pointer_api_service.dart';
import 'package:auth_app/domain/entities/building_entity.dart';
import 'package:auth_app/service_locator.dart';
import 'package:dartz/dartz.dart';
import 'package:auth_app/data/models/pointer.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import '../../domain/repository/pointers.dart';

class PointersRepositoryImpl implements PointersRepository {
  List<Pointer>? _cache;

  @override
  Future<Either<String, List<Pointer>>> getPointers() async {
    final result = await sl<PointerApiService>().getPointers();
    return result.fold(
      (errorMessage) {
        return Left(errorMessage);
      },
      (response) {
        try {
          final pointers = (response.data as List)
              .map((json) => Pointer.fromJson(json))
              .toList();
          _cache = pointers;
          return Right(pointers);
        } catch (e) {
          return Left('Failed to parse pointers');
        }
      },
    );
  }

  Future<List<BuildingEntity>> getBuildings() async {
    if (_cache == null) {
      final response = await getPointers();
      return response.fold(
        (errorMessage) {
          throw Exception(errorMessage);
        },
        (pointers) {
          _cache = pointers;
          return pointers.where((pointer) => pointer.contourWKT != null).map((pointer) {
            return BuildingEntity(
              name: pointer.name,
              polygon: pointer.contourWKT!.toString(),
            );
          }).toList();
        },
      );
    }else{
      return _cache!.where((pointer) => pointer.contourWKT != null).map((pointer) {
        return BuildingEntity(
          name: pointer.name,
          polygon: pointer.contourWKT!.toString(),
        );
      }).toList();
    }
  }

  @override
  Future<BuildingEntity?> findBuildingAt(LatLng point) async {
    final buildings = await getBuildings();
    print('🔍 Checking point: ${point.latitude}, ${point.longitude}');
    print('📍 Total buildings to check: ${buildings.length}');
    
    for (final building in buildings) {
      print('🏢 Checking ${building.name}');
      
      if (building.name == 'Chemiegebäude') {
        print('🧪 DEBUGGING CHEMIEGEBÄUDE:');
        print('WKT: ${building.polygon.substring(0, 100)}...');
      }
      
      final isInside = pointInPolygon(point, building.polygon);
      print('Result for ${building.name}: $isInside');
      
      if (isInside) {
        print('✅ Found building: ${building.name}');
        return building;
      }
    }
    
    print('🚫 No building found at clicked location');
    return null;
  }
}
