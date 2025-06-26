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
    return ScooterRouteSegment(
      type: map['Type'] ?? '',
      polyline: (map['Polyline'] as List)
          .map<LatLng>((e) => LatLng(e[0], e[1]))
          .toList(),
      durationSeconds: map['DurationSeconds'] ?? 0,
      distanceMeters: (map['DistanceMeters'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FindScooterRouteSegment {
  final LatLng start;
  final LatLng end;
  final double distanceMeters;
  final int durationSeconds;
  final List<ScooterRouteSegment> segments;

  FindScooterRouteSegment({
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.segments,
  });

  factory FindScooterRouteSegment.fromJson(Map<String, dynamic> map) {
    return FindScooterRouteSegment(
      start: LatLng(map['Start'][0], map['Start'][1]),
      end: LatLng(map['End'][0], map['End'][1]),
      distanceMeters: (map['DistanceMeters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: map['DurationSeconds'] ?? 0,
      segments: (map['Segments'] as List)
          .map((e) => ScooterRouteSegment.fromJson(e))
          .toList(),
    );
  }

  factory FindScooterRouteSegment.fromSegmentsList(List<dynamic> list) {
  final segments = list
      .map((e) => ScooterRouteSegment.fromJson(e as Map<String, dynamic>))
      .toList();

  return FindScooterRouteSegment(
    start: segments.first.polyline.first,
    end: segments.last.polyline.last,
    distanceMeters: segments.fold(0.0, (sum, s) => sum + s.distanceMeters),
    durationSeconds: segments.fold(0, (sum, s) => sum + s.durationSeconds),
    segments: segments,
  );
}
}

class FindScooterRouteResponse {
  final List<ScooterRouteSegment> segments;

  FindScooterRouteResponse({
    required this.segments,
  });

  factory FindScooterRouteResponse.fromJson(List<dynamic>  json) {
    return FindScooterRouteResponse(
      segments: json
          .map((e) => ScooterRouteSegment.fromJson(e))
          .toList(),
    );
  }
}