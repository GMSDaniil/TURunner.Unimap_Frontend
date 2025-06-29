import 'package:latlong2/latlong.dart';

bool pointInPolygon(LatLng point, dynamic polygon) {
  List<LatLng> polygonPoints;
  
  if (polygon is String) {
    // Check if it's a stringified List<LatLng>
    if (polygon.startsWith('[LatLng(')) {
      polygonPoints = _parseStringifiedLatLngList(polygon);
    } else {
      polygonPoints = _parseWKTToLatLng(polygon);
    }
    
    if (polygonPoints.isEmpty) {
      return false;
    }
  } else if (polygon is List<LatLng>) {
    polygonPoints = polygon;
  } else if (polygon is List) {
    try {
      polygonPoints = List<LatLng>.from(polygon);
    } catch (e) {
      return false;
    }
  } else {
    return false;
  }
  
  if (polygonPoints.isEmpty) {
    return false;
  }
  
  // Quick bounding box check for performance
  double minLat = polygonPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
  double maxLat = polygonPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
  double minLng = polygonPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
  double maxLng = polygonPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
  
  bool withinBounds = point.latitude >= minLat && point.latitude <= maxLat && 
                     point.longitude >= minLng && point.longitude <= maxLng;
  
  if (!withinBounds) {
    return false;
  }
  
  // Ray-casting algorithm for precise point-in-polygon test
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

/// Parses stringified List<LatLng> format: "[LatLng(latitude:52.51373, longitude:13.325104), ...]"
List<LatLng> _parseStringifiedLatLngList(String listString) {
  try {
    final RegExp latLngRegex = RegExp(r'LatLng\(latitude:([\d.-]+),\s*longitude:([\d.-]+)\)');
    final matches = latLngRegex.allMatches(listString);
    
    final points = <LatLng>[];
    for (final match in matches) {
      final lat = double.parse(match.group(1)!);
      final lng = double.parse(match.group(2)!);
      
      // Basic coordinate validation for Berlin area
      if (lat >= 52.3 && lat <= 52.7 && lng >= 13.0 && lng <= 13.8) {
        points.add(LatLng(lat, lng));
      }
    }
    
    return points;
  } catch (e) {
    return [];
  }
}

/// Parses Well-Known Text (WKT) format: "POLYGON((lng lat, lng lat, ...))"
List<LatLng> _parseWKTToLatLng(String wkt) {
  try {
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
          
          // Basic coordinate validation for Berlin area
          if (latitude >= 52.3 && latitude <= 52.7 && 
              longitude >= 13.0 && longitude <= 13.8) {
            points.add(LatLng(latitude, longitude));
          }
        } catch (e) {
          // Skip invalid coordinates
          continue;
        }
      }
    }
    
    return points;
  } catch (e) {
    return [];
  }
}