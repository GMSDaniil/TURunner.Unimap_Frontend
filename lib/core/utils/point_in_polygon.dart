import 'package:latlong2/latlong.dart';

bool pointInPolygon(LatLng point, List<LatLng> polygon) {
  int intersectCount = 0;
  for (int j = 0; j < polygon.length - 1; j++) {
    if (((polygon[j].latitude > point.latitude) != (polygon[j + 1].latitude > point.latitude)) &&
        (point.longitude <
            (polygon[j + 1].longitude - polygon[j].longitude) *
                    (point.latitude - polygon[j].latitude) /
                    (polygon[j + 1].latitude - polygon[j].latitude) +
                polygon[j].longitude)) {
      intersectCount++;
    }
  }
  return (intersectCount % 2) == 1;
}