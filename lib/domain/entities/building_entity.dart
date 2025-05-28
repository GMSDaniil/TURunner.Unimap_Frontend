import 'package:latlong2/latlong.dart';

class BuildingEntity {
  final String name;
  final List<LatLng> polygon;

  BuildingEntity({
    required this.name,
    required this.polygon,
  });
}