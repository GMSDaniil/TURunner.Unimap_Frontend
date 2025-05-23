class FindRouteReqParams {
  final double startLat;
  final double startLon;
  final double endLat;
  final double endLon;
  final String profile; // e.g., 'foot', 'car', etc.

  FindRouteReqParams({
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    this.profile = 'foot',
  });
  
  Map<String, String> toMap() {
    return {
      'point1': '$startLat,$startLon',
      'point2': '$endLat,$endLon',
      'profile': profile,
    };
  }
}