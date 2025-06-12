import 'package:latlong2/latlong.dart';

class ScooterRouteSegment {
  final String type; // "walk" or "transit"
  final List<LatLng> polyline;
  final int durationSeconds;
  final double distanceMeters;

  ScooterRouteSegment({
    required this.type,
    required this.polyline,
    required this.durationSeconds,
    required this.distanceMeters,
  });

  

  factory ScooterRouteSegment.fromJson(Map<String, dynamic> map) {
  final raw = map['Polyline'];

  // 1) If it’s already a List<[lat,lon]>, map it directly.
  // 2) If it’s a String, run a polyline‐decoder on it.
  final List<LatLng> decoded;
  if (raw is List) {
    decoded = raw
      .cast<List<dynamic>>()
      .map((pair) => LatLng(
         (pair[0] as num).toDouble(),
         (pair[1] as num).toDouble(),
      ))
      .toList();
  } else if (raw is String) {
    decoded = decodePolyline(raw);  // see helper below
  } else {
    decoded = [];
  }

  return ScooterRouteSegment(
    type:            map['Type']   ?? '',
    polyline:        decoded,
    durationSeconds: map['DurationSeconds'] ?? 0,
    distanceMeters:  (map['DistanceMeters'] as num?)?.toDouble() ?? 0.0,
  );
}
}
List<LatLng> decodePolyline(String encoded) {
  final List<LatLng> poly = [];
  int index = 0, lat = 0, lng = 0;

  while (index < encoded.length) {
    int shift = 0, result = 0, b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

    poly.add(LatLng(lat / 1E5, lng / 1E5));
  }

  return poly;
}

class FindScooterRouteResponse {
  final LatLng start;
  final LatLng end;
  final double distanceMeters;
  final int durationSeconds;
  final List<ScooterRouteSegment> segments;

  FindScooterRouteResponse({
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.segments,
  });

  factory FindScooterRouteResponse.fromJson(Map<String, dynamic> map) {
    return FindScooterRouteResponse(
      start: LatLng(map['Start'][0], map['Start'][1]),
      end: LatLng(map['End'][0], map['End'][1]),
      distanceMeters: (map['DistanceMeters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: map['DurationSeconds'] ?? 0,
      segments: (map['Segments'] as List)
          .map((e) => ScooterRouteSegment.fromJson(e))
          .toList(),
    );
  }

  factory FindScooterRouteResponse.fromSegmentsList(List<dynamic> list) {
  final segments = list
      .map((e) => ScooterRouteSegment.fromJson(e as Map<String, dynamic>))
      .toList();

  return FindScooterRouteResponse(
    start: segments.first.polyline.first,
    end: segments.last.polyline.last,
    distanceMeters: segments.fold(0.0, (sum, s) => sum + s.distanceMeters),
    durationSeconds: segments.fold(0, (sum, s) => sum + s.durationSeconds),
    segments: segments,
  );
}
}