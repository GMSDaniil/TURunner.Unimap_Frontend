import 'package:auth_app/data/models/route_segment.dart';

class RouteData {
  final List<RouteSegment> segments;

  RouteData({required this.segments});

  double get totalDistance => segments.fold(0, (sum, s) => sum + s.distanceMeters);
  int get totalDuration => segments.fold(0, (sum, s) => sum + s.durrationSeconds);
}