class Pointer {
  final String name;
  final double lat;
  final double lng;
  final String category;

  Pointer({
    required this.name,
    required this.lat,
    required this.lng,
    required this.category,
  });

  factory Pointer.fromJson(Map<String, dynamic> json) {
    final lat = json['lat'] ?? json['Latitude'];
    final lng = json['lng'] ?? json['Longitude'];
    if (lat == null || lng == null) {
      throw Exception('Missing lat/lng in Pointer JSON: $json');
    }
    return Pointer(
      name: json['name'] ?? json['Name'] ?? '',
      lat: (lat as num).toDouble(),
      lng: (lng as num).toDouble(),
      category: json['category'] ?? json['Category'] ?? '',
    );
  }
}