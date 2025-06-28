import 'package:latlong2/latlong.dart';

class BuildingEntity {
  final String name;
  final String polygon; // ← Change from List<LatLng> to String
  final double? latitude;
  final double? longitude;

  BuildingEntity({
    required this.name,
    required this.polygon,
    this.latitude,
    this.longitude,
  });
}