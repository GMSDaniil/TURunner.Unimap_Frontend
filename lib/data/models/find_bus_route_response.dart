import 'package:latlong2/latlong.dart';

class BusRouteSegment {
  final String type; // "walk" or "transit"
  final List<LatLng> polyline;
  final int durationSeconds;
  final double distanceMeters;
  final List<LatLng>? precisePolyline;
  final String? transportType;
  final String? transportLine;
  final String? fromStop;
  final String? toStop;

  BusRouteSegment({
    required this.type,
    required this.polyline,
    required this.durationSeconds,
    required this.distanceMeters,
    this.precisePolyline,
    this.transportType,
    this.transportLine,
    this.fromStop,
    this.toStop,
  });

  factory BusRouteSegment.fromJson(Map<String, dynamic> map) {
    return BusRouteSegment(
      type: map['Type'] ?? '',
      polyline: (map['Polyline'] as List)
          .map<LatLng>((e) => LatLng(e[0], e[1]))
          .toList(),
      
      durationSeconds: map['DurationSeconds'] ?? 0,
      distanceMeters: (map['DistanceMeters'] as num?)?.toDouble() ?? 0.0,
      transportType: map['TransportType'],
      precisePolyline: (map['precisePolyline'] as List?)
          ?.map<LatLng>((e) => LatLng(e[0], e[1]))
          .toList(),
      transportLine: map['TransportLine'],
      fromStop: map['FromStop'],
      toStop: map['ToStop'],
    );
  }
}

class FindBusRouteResponseSegment {
  final LatLng start;
  final LatLng end;
  final List<BusRouteSegment> segments;
  final int durationSeconds;
  final double distanceMeters;

  FindBusRouteResponseSegment({
    required this.start,
    required this.end,
    required this.segments,
    required this.durationSeconds,
    required this.distanceMeters,
  });

  factory FindBusRouteResponseSegment.fromJson(Map<String, dynamic> map) {
    return FindBusRouteResponseSegment(
      start: LatLng(map['Start'][0], map['Start'][1]),
      end: LatLng(map['End'][0], map['End'][1]),
      distanceMeters: (map['DistanceMeters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: map['DurationSeconds'] ?? 0,
      segments: (map['Segments'] as List)
          .map((e) => BusRouteSegment.fromJson(e))
          .toList(),
    );
  }
}

class FindBusRouteResponse {
  List<FindBusRouteResponseSegment> segments;

  FindBusRouteResponse({
    required this.segments,
  });

  factory FindBusRouteResponse.fromJson(List<dynamic> json) {
    return FindBusRouteResponse(
      segments: json
          .map((e) => FindBusRouteResponseSegment.fromJson(e))
          .toList(),
    );
  }
}