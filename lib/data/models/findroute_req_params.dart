class FindRouteReqParams {
  final double fromLat;
  final double fromLon;
  final double toLat;
  final double toLon;
  // final String profile; // e.g., 'foot', 'car', etc.

  FindRouteReqParams({
    required this.fromLat,
    required this.fromLon,
    required this.toLat,
    required this.toLon,
    // this.profile = 'foot',
  });
  
  Map<String, String> toMap() {
    return {
      'fromLat': fromLat.toString(),
      'fromLon': fromLon.toString(),
      'toLat': toLat.toString(),
      'toLon': toLon.toString(),
      // 'profile': profile,
    };
  }
}