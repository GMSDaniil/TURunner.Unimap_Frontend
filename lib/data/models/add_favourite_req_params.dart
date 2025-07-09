class AddFavouriteReqParams {
  final String name;
  final double latitude;
  final double longitude;
  final int placeId;

  AddFavouriteReqParams({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.placeId,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'placeId': placeId,
  };
}
