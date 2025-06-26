import 'package:latlong2/latlong.dart';

class WalkingRouteSegment{
  final LatLng start;
  final LatLng end;
  final double distanceMeters;
  final int durationSeconds;
  final List<LatLng> foot;


  WalkingRouteSegment({
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.foot,
  });

  factory WalkingRouteSegment.fromJson(Map<String, dynamic> map) {
    return WalkingRouteSegment(
      start: LatLng(map['Start'][0], map['Start'][1]),
      end: LatLng(map['End'][0], map['End'][1]),
      distanceMeters: map['DistanceMeters'].toDouble(),
      durationSeconds: map['DurationSeconds'],
      foot: (map['Polyline'] as List).map((e) => LatLng(e[0], e[1])).toList(),
    );
  }
}

class FindRouteResponse {
  final List<WalkingRouteSegment> segments;


  FindRouteResponse({
    required this.segments,
  });

  factory FindRouteResponse.fromJson(List<dynamic> json) {
    return FindRouteResponse(
      segments: json 
          .map((e) => WalkingRouteSegment.fromJson(e))
          .toList(),
    );
  }
}