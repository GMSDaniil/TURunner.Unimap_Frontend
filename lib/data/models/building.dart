import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import 'package:auth_app/domain/entities/building_entity.dart';

class BuildingModel extends BuildingEntity {
  BuildingModel({required String name, required String polygon})
      : super(name: name, polygon: polygon);

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    // ÄNDERUNG: Die Feldnamen an das campus_buildings.json angepasst
    return BuildingModel(
      name: json['Name'], // vorher: json['name']
      polygon: json['Contour'],
    );
  }
}

/// Parsen von WKT-MULTIPOLYGON für campus_buildings.json.
/// Gibt den größten Ring als List<LatLng> zurück.
/// ÄNDERUNG: Funktioniert jetzt direkt mit dem WKT-Format aus campus_buildings.json.
List<LatLng> parsePolygonOrMultiPolygonFromWKT(String wkt) {
  // Entfernt "MULTIPOLYGON (((" und ")))"
  final cleaned = wkt
      .replaceAll('MULTIPOLYGON (((', '')
      .replaceAll(')))', '')
      .replaceAll('(', '')
      .replaceAll(')', '');

  // Jeder Ring ist durch "), (" getrennt, wir nehmen den größten Ring
  final rings = cleaned.split('), (');
  List<LatLng> largestRing = [];
  for (final ring in rings) {
    final points = ring.trim().split(',');
    final latlngs = points.map((point) {
      final coords = point.trim().split(' ');
      // WKT ist "lng lat"
      final lng = double.parse(coords[0]);
      final lat = double.parse(coords[1]);
      return LatLng(lat, lng);
    }).toList();
    if (latlngs.length > largestRing.length) {
      largestRing = latlngs;
    }
  }
  return largestRing;
}

// Helper to read a 32-bit unsigned integer.
int _readUint32(ByteData byteData, int offset, bool isLE) =>
    isLE ? byteData.getUint32(offset, Endian.little) : byteData.getUint32(offset, Endian.big);

// Helper to read a 64-bit float.
double _readFloat64(ByteData byteData, int offset, bool isLE) =>
    isLE ? byteData.getFloat64(offset, Endian.little) : byteData.getFloat64(offset, Endian.big);

// Änderungen:
// - Feldnamen in fromJson an campus_buildings.json angepasst (Name statt name)
// - parsePolygonOrMultiPolygonFromWKT für campus_buildings.json optimiert (WKT statt WKB)