import 'package:latlong2/latlong.dart';

bool pointInPolygon(LatLng point, String polygonWKT) {
  final polygonPoints = _parseWKTToLatLng(polygonWKT);
  if (polygonPoints.isEmpty) {
    print('❌ Failed to parse WKT polygon');
    return false;
  }
  
  // Ray-casting algorithm
  bool inside = false;
  int j = polygonPoints.length - 1;
  
  for (int i = 0; i < polygonPoints.length; i++) {
    final xi = polygonPoints[i].longitude;
    final yi = polygonPoints[i].latitude;
    final xj = polygonPoints[j].longitude;
    final yj = polygonPoints[j].latitude;
    
    if (((yi > point.latitude) != (yj > point.latitude)) &&
        (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
    j = i;
  }
  
  return inside;
}

List<LatLng> _parseWKTToLatLng(String wkt) {
  try {
    // Handle MULTIPOLYGON and POLYGON formats
    String coordString = wkt
        .replaceAll(RegExp(r'MULTIPOLYGON\s*\(\(\('), '')
        .replaceAll(RegExp(r'POLYGON\s*\(\('), '')
        .replaceAll(RegExp(r'\)\)\).*$'), '')
        .replaceAll(RegExp(r'\)\).*$'), '');
    
    final coords = coordString.split(',');
    final points = <LatLng>[];
    
    for (String coord in coords) {
      final parts = coord.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        try {
          // WKT format: longitude latitude
          final longitude = double.parse(parts[0]);
          final latitude = double.parse(parts[1]);
          
          // Validate Berlin coordinates
          if (latitude >= 52.3 && latitude <= 52.7 && 
              longitude >= 13.0 && longitude <= 13.8) {
            points.add(LatLng(latitude, longitude));
          }
        } catch (e) {
          print('Error parsing coordinate: $coord');
        }
      }
    }
    
    return points;
  } catch (e) {
    print('Error parsing WKT: $e');
    return [];
  }
}