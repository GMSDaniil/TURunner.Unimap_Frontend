import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:latlong2/latlong.dart';

class RouteSegment {
  final TravelMode mode;
  final List<LatLng> path;
  final double distanceMeters;
  final int durrationSeconds;
  final List<LatLng>? precisePolyline;
  final String? transportType;
  final String? transportLine;
  final String? fromStop;
  final String? toStop;

  RouteSegment({
    required this.mode,
    required this.path,
    required this.distanceMeters,
    required this.durrationSeconds,
    this.precisePolyline,
    this.transportType,
    this.transportLine,
    this.fromStop,
    this.toStop,
  });
}