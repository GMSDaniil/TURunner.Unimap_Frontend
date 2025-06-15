import 'package:auth_app/domain/repository/pointers.dart';
import 'package:auth_app/service_locator.dart';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/domain/entities/building_entity.dart';

class FindBuildingAtPoint{

  @override
  Future<BuildingEntity?> call({LatLng? point}) async {
  if (point == null) {
      print('Point cannot be null');
    }
    return await sl<PointersRepository>().findBuildingAt(point!);
  } 
  
}