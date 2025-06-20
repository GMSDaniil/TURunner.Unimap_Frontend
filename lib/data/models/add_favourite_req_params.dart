class AddFavouriteReqParams {
  final String userId;
  final String pointerId;

  AddFavouriteReqParams({required this.userId, required this.pointerId});

  Map<String, dynamic> toJson() => {'userId': userId, 'pointerId': pointerId};
}
