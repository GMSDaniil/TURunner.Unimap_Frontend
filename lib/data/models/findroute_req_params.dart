class FindRouteReqParams {
  final List<MapPoint> points;
  // final String profile; // e.g., 'foot', 'car', etc.

  FindRouteReqParams({
    required this.points,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => p.toMap()).toList(),
      // 'profile': profile,
    };
  }
}

class MapPoint {
  final double lat;
  final double lon;

  MapPoint(this.lat, this.lon);

  Map<String, double> toMap() {
    return {
      'lat': lat,
      'lon': lon,
    };
  }
}