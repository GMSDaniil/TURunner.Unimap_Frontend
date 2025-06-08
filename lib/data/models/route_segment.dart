import 'package:auth_app/presentation/widgets/route_options_sheet.dart';
import 'package:latlong2/latlong.dart';

class RouteSegment {
  final TravelMode mode;
  final List<LatLng> path;
  final double distanceMeters;
  final int durationMilliseconds;

  RouteSegment({
    required this.mode,
    required this.path,
    required this.distanceMeters,
    required this.durationMilliseconds,
  });
}