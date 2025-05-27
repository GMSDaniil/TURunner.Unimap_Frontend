class GetPointersRequest {
  final double northEastLat;
  final double northEastLng;
  final double southWestLat;
  final double southWestLng;
  final String? category; // optional filter

  GetPointersRequest({
    required this.northEastLat,
    required this.northEastLng,
    required this.southWestLat,
    required this.southWestLng,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'northEastLat': northEastLat,
      'northEastLng': northEastLng,
      'southWestLat': southWestLat,
      'southWestLng': southWestLng,
      if (category != null) 'category': category,
    };
  }
}
