import 'package:latlong2/latlong.dart';

class FindRouteResponse{
  final LatLng start;
  final LatLng end;
  final double distanceMeters;
  final int durationMilliseconds;
  final List<LatLng> foot;


  FindRouteResponse({
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.durationMilliseconds,
    required this.foot,
  });

  factory FindRouteResponse.fromJson(Map<String, dynamic> map) {
    return FindRouteResponse(
      start: LatLng(map['Start'][0], map['Start'][1]),
      end: LatLng(map['End'][0], map['End'][1]),
      distanceMeters: map['DistanceMeters'].toDouble(),
      durationMilliseconds: map['DurationSeconds'], // It's actually milliseconds
      foot: (map['Polyline'] as List).map((e) => LatLng(e[0], e[1])).toList(),
    );
  }
}