import 'package:latlong2/latlong.dart';

class FindRouteResponse{
  final List<LatLng> foot;
  final List<LatLng> bus;
  final List<LatLng> scooter;

  FindRouteResponse({
    required this.foot,
    required this.bus,
    required this.scooter,
  });

  factory FindRouteResponse.fromJson(Map<String, dynamic> map) {
    return FindRouteResponse(
      foot: (map['foot'] as List).map((e) => LatLng(e[0], e[1])).toList(),
      bus: (map['bus'] as List).map((e) => LatLng(e[0], e[1])).toList(),
      scooter: (map['scooter'] as List).map((e) => LatLng(e[0], e[1])).toList(),
    );
  }
}