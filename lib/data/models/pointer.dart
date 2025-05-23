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
    return Pointer(
      name: json['name'],
      lat: json['lat'],
      lng: json['lng'],
      category: json['category'],
    );
  }
}