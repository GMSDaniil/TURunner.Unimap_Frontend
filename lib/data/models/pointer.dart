import 'package:latlong2/latlong.dart';

class Pointer {
  final String name;
  final double lat;
  final double lng;
  final String category;
  final String? description;
  List<String> rooms = [];
  final List<LatLng>? contourWKT;
  

  Pointer({
    required this.name,
    required this.lat,
    required this.lng,
    required this.category,
    this.rooms = const [],
    this.description,
    this.contourWKT,
  });

  factory Pointer.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'];
    final lng = json['longitude'];
    if (lat == null || lng == null) {
      throw Exception('Missing lat/lng in Pointer JSON: $json');
    }
    return Pointer(
      name: json['name'] ?? '',
      lat: (lat as num).toDouble(),
      lng: (lng as num).toDouble(),
      category: json['category'] ?? '',
      description: json['description'] ,
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((room) => room.toString())
              .toList() ??
          [],
      contourWKT: json['contourWKT'] != null
          ? parsePolygonOrMultiPolygonFromWKT(json['contourWKT'])
          : null,
    );
  }
}

List<LatLng> parsePolygonOrMultiPolygonFromWKT(String wkt) {
  // Entfernt "MULTIPOLYGON (((" und ")))"
  final cleaned = wkt
      .replaceAll('MULTIPOLYGON(((', '')
      .replaceAll(')))', '')
      .replaceAll('(', '')
      .replaceAll(')', '');

  // Jeder Ring ist durch "), (" getrennt, wir nehmen den größten Ring
  final rings = cleaned.split('), (');
  List<LatLng> largestRing = [];
  for (final ring in rings) {
    final points = ring.trim().split(',');
    final latlngs = points.map((point) {
      final coords = point.trim().split(' ');
      // WKT ist "lng lat"
      final lng = double.parse(coords[0]);
      final lat = double.parse(coords[1]);
      return LatLng(lat, lng);
    }).toList();
    if (latlngs.length > largestRing.length) {
      largestRing = latlngs;
    }
  }
  return largestRing;
}