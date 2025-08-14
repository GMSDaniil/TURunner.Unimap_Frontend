class FavouriteEntity {
  final String id;
  final int? placeId;
  final String name;
  final double lat;
  final double lng;

  FavouriteEntity({
    required this.id,
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
  });

  factory FavouriteEntity.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int? _toIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return FavouriteEntity(
      id: (json['id'] ?? '').toString(),
      placeId: _toIntOrNull(json['placeId']),
      name: (json['name'] ?? '').toString(),
      lat: _toDouble(json['latitude']),
      lng: _toDouble(json['longitude']),
    );
  }
}
