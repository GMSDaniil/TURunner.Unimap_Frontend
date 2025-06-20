class GetFavouritesReqParams {
  final String userId;

  GetFavouritesReqParams({required this.userId});

  Map<String, dynamic> toJson() => {'userId': userId};
}
